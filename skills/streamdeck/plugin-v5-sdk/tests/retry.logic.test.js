const test = require('node:test');
const assert = require('node:assert/strict');
const { shouldRetryGatewayResult, computeBackoffMs, executeWithRetry } = require('../lib/retry');

test('shouldRetryGatewayResult retries transient codes only when attempts remain', () => {
  assert.equal(shouldRetryGatewayResult({ status: 0 }, 1, 3), true);
  assert.equal(shouldRetryGatewayResult({ status: 429 }, 1, 3), true);
  assert.equal(shouldRetryGatewayResult({ status: 503 }, 1, 3), true);
  assert.equal(shouldRetryGatewayResult({ status: 404 }, 1, 3), false);
  assert.equal(shouldRetryGatewayResult({ status: 401 }, 1, 3), false);
  assert.equal(shouldRetryGatewayResult({ status: 503 }, 3, 3), false);
});

test('computeBackoffMs applies bounded exponential backoff', () => {
  assert.equal(computeBackoffMs(250, 1), 250);
  assert.equal(computeBackoffMs(250, 2), 500);
  assert.equal(computeBackoffMs(250, 3), 1000);
  assert.equal(computeBackoffMs(10, 1), 50);
  assert.equal(computeBackoffMs(250, 6, { maxBackoffMs: 1200 }), 1200);
});

test('shouldRetryGatewayResult retries thrown errors while attempts remain', () => {
  assert.equal(shouldRetryGatewayResult(null, 1, 2, new Error('socket closed')), true);
  assert.equal(shouldRetryGatewayResult(null, 2, 2, new Error('socket closed')), false);
});

test('executeWithRetry fault injection: recovers from transient failure', async () => {
  let calls = 0;
  const out = await executeWithRetry({
    maxRetries: 2,
    baseBackoffMs: 1,
    operation: async ({ attempt, maxAttempts }) => {
      calls++;
      if (attempt === 1) return { ok: false, status: 503, attempt, maxAttempts };
      return { ok: true, status: 200, attempt, maxAttempts };
    },
    shouldRetry: ({ result, attempt, maxAttempts }) => shouldRetryGatewayResult(result, attempt, maxAttempts)
  });

  assert.equal(out.result.ok, true);
  assert.equal(out.attempt, 2);
  assert.equal(calls, 2);
});

test('executeWithRetry fault injection: stops on non-retryable response', async () => {
  let calls = 0;
  const out = await executeWithRetry({
    maxRetries: 3,
    baseBackoffMs: 1,
    operation: async ({ attempt, maxAttempts }) => {
      calls++;
      return { ok: false, status: 404, attempt, maxAttempts };
    },
    shouldRetry: ({ result, attempt, maxAttempts }) => shouldRetryGatewayResult(result, attempt, maxAttempts)
  });

  assert.equal(out.result.status, 404);
  assert.equal(out.attempt, 1);
  assert.equal(calls, 1);
});

test('executeWithRetry fault injection: exhausts retries on repeated transient failures', async () => {
  let calls = 0;
  const out = await executeWithRetry({
    maxRetries: 2,
    baseBackoffMs: 1,
    operation: async ({ attempt, maxAttempts }) => {
      calls++;
      return { ok: false, status: 503, attempt, maxAttempts };
    },
    shouldRetry: ({ result, attempt, maxAttempts }) => shouldRetryGatewayResult(result, attempt, maxAttempts)
  });

  assert.equal(out.result.status, 503);
  assert.equal(out.attempt, 3);
  assert.equal(calls, 3);
});

test('executeWithRetry does not sleep after final attempt', async () => {
  const started = Date.now();
  const out = await executeWithRetry({
    maxRetries: 0,
    baseBackoffMs: 500,
    operation: async ({ attempt, maxAttempts }) => ({ ok: false, status: 503, attempt, maxAttempts }),
    shouldRetry: () => true
  });

  const elapsedMs = Date.now() - started;
  assert.equal(out.attempt, 1);
  assert.ok(elapsedMs < 250, `unexpected backoff wait on final attempt: ${elapsedMs}ms`);
});
