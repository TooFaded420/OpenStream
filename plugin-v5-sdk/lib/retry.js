function shouldRetryGatewayResult(result, attempt, maxAttempts, error = null) {
  if (attempt >= maxAttempts) return false;
  if (error) return true;
  if (!result) return false;
  if (result.status === 0) return true;
  if (result.status === 429) return true;
  if (result.status >= 500) return true;
  return false;
}

function clampNumber(input, min, max, fallback) {
  const n = Number(input);
  if (!Number.isFinite(n)) return fallback;
  return Math.max(min, Math.min(max, n));
}

function computeBackoffMs(baseBackoffMs, attempt, options = {}) {
  const base = clampNumber(baseBackoffMs, 50, 60000, 250);
  const maxBackoffMs = clampNumber(options?.maxBackoffMs, base, 60000, 10000);
  const jitterRatio = clampNumber(options?.jitterRatio, 0, 0.5, 0);
  const exponent = Math.max(0, Number(attempt || 1) - 1);
  const capped = Math.min(maxBackoffMs, base * Math.pow(2, exponent));
  if (jitterRatio <= 0) return capped;
  const jitterWindow = capped * jitterRatio;
  const jitterOffset = (Math.random() * jitterWindow * 2) - jitterWindow;
  return Math.max(0, Math.round(capped + jitterOffset));
}

function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

async function executeWithRetry(options) {
  const maxRetries = Math.max(0, Number(options?.maxRetries || 0));
  const maxAttempts = maxRetries + 1;
  const baseBackoffMs = Number(options?.baseBackoffMs || 250);
  const maxBackoffMs = Number(options?.maxBackoffMs || 10000);
  const jitterRatio = Number(options?.jitterRatio || 0);
  const operation = options?.operation;
  const shouldRetry = options?.shouldRetry;
  const onRetry = options?.onRetry;

  if (typeof operation !== 'function') {
    throw new Error('executeWithRetry requires an operation function');
  }
  if (typeof shouldRetry !== 'function') {
    throw new Error('executeWithRetry requires a shouldRetry function');
  }

  let lastResult;
  let lastError;

  for (let attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      const result = await operation({ attempt, maxAttempts });
      lastResult = result;

      if (!shouldRetry({ result, attempt, maxAttempts, error: null })) {
        return { result, attempt, maxAttempts, error: null };
      }

      if (attempt >= maxAttempts) {
        return { result, attempt, maxAttempts, error: null };
      }

      const backoffMs = computeBackoffMs(baseBackoffMs, attempt, { maxBackoffMs, jitterRatio });
      if (typeof onRetry === 'function') {
        await onRetry({ attempt, maxAttempts, backoffMs, result, error: null });
      }
      await sleep(backoffMs);
    } catch (error) {
      lastError = error;
      if (!shouldRetry({ result: null, attempt, maxAttempts, error })) {
        throw error;
      }

      if (attempt >= maxAttempts) {
        throw error;
      }

      const backoffMs = computeBackoffMs(baseBackoffMs, attempt, { maxBackoffMs, jitterRatio });
      if (typeof onRetry === 'function') {
        await onRetry({ attempt, maxAttempts, backoffMs, result: null, error });
      }
      await sleep(backoffMs);
    }
  }

  if (lastResult !== undefined) {
    return { result: lastResult, attempt: maxAttempts, maxAttempts, error: null };
  }
  throw lastError || new Error('Retry attempts exhausted');
}

module.exports = {
  shouldRetryGatewayResult,
  computeBackoffMs,
  executeWithRetry
};
