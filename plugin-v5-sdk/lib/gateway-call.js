const { executeWithRetry, shouldRetryGatewayResult } = require('./retry');
const fs = require('fs');
const path = require('path');
const { promisify } = require('util');
const { execFile } = require('child_process');

const execFileAsync = promisify(execFile);
const DEFAULT_SESSION_KEY = 'agent:main:main';

function clampNumber(input, min, max, fallback) {
  const n = Number(input);
  if (!Number.isFinite(n)) return fallback;
  return Math.max(min, Math.min(max, n));
}

function normalizeGatewayInput(gw) {
  if (!gw || typeof gw !== 'object') return null;
  const rawUrl = typeof gw.url === 'string' ? gw.url.trim() : '';
  if (!rawUrl) return null;
  try {
    const parsed = new URL(rawUrl);
    if (parsed.protocol !== 'http:' && parsed.protocol !== 'https:') return null;
    const key = typeof gw.key === 'string' && gw.key.trim() ? gw.key.trim() : 'default';
    const token = typeof gw.token === 'string' && gw.token.trim() ? gw.token.trim() : null;
    return { key, url: parsed.toString().replace(/\/$/, ''), token };
  } catch {
    return null;
  }
}

function normalizeGatewayPath(rawPath) {
  if (typeof rawPath !== 'string') return null;
  const trimmed = rawPath.trim();
  if (!trimmed) return null;
  if (/^https?:\/\//i.test(trimmed)) return null;
  return trimmed.startsWith('/') ? trimmed : `/${trimmed}`;
}

function safeLog(log, level, event, meta) {
  try {
    log(level, event, meta);
  } catch {
    // logging should not break gateway calls
  }
}

function safeErrCode(errCode, result) {
  if (typeof errCode !== 'function') return 'ERR';
  try {
    const value = errCode(result);
    return value ? String(value) : 'ERR';
  } catch {
    return 'ERR';
  }
}

function safeRecordTelemetry(recordTelemetry, action, status, latencyMs, code, details, log) {
  if (typeof recordTelemetry !== 'function') return;
  try {
    recordTelemetry(action, status, latencyMs, code, details);
  } catch (error) {
    safeLog(log, 'warn', 'gateway.telemetry_failed', { error: String(error) });
  }
}

function makeFailureResult({ gatewayKey, error, latencyMs = 0, attempt = 1, maxAttempts = 1 }) {
  return {
    ok: false,
    status: 0,
    data: { error: String(error || 'Unknown gateway error') },
    gateway: gatewayKey || 'default',
    latencyMs,
    attempt,
    maxAttempts
  };
}

function toGatewayWsUrl(url) {
  if (typeof url !== 'string' || !url.trim()) return null;
  try {
    const parsed = new URL(url.trim());
    if (parsed.protocol === 'http:') parsed.protocol = 'ws:';
    else if (parsed.protocol === 'https:') parsed.protocol = 'wss:';
    if (parsed.protocol !== 'ws:' && parsed.protocol !== 'wss:') return null;
    return parsed.toString();
  } catch {
    return null;
  }
}

function setPathValue(target, dottedPath, value) {
  if (!target || typeof target !== 'object' || typeof dottedPath !== 'string') return false;
  const parts = dottedPath.split('.').map(x => x.trim()).filter(Boolean);
  if (!parts.length) return false;
  let node = target;
  for (let i = 0; i < parts.length - 1; i += 1) {
    const key = parts[i];
    const next = node[key];
    if (!next || typeof next !== 'object' || Array.isArray(next)) {
      node[key] = {};
    }
    node = node[key];
  }
  node[parts[parts.length - 1]] = value;
  return true;
}

function normalizeModelId(model) {
  if (typeof model !== 'string' || !model.trim()) return null;
  const raw = model.trim();
  if (raw.startsWith('openai/')) return raw;
  if (raw.startsWith('synthetic/')) return raw.toLowerCase();
  if (raw.startsWith('hf:')) return `synthetic/${raw.toLowerCase()}`;
  if (/^gpt-/i.test(raw)) return `openai/${raw.toLowerCase()}`;
  return raw.toLowerCase();
}

function normalizeSessionKey(sessionKey) {
  if (typeof sessionKey !== 'string') return DEFAULT_SESSION_KEY;
  const trimmed = sessionKey.trim();
  return trimmed || DEFAULT_SESSION_KEY;
}

function normalizeSearchCount(value) {
  const parsed = Number(value);
  if (!Number.isFinite(parsed)) return 3;
  const rounded = Math.floor(parsed);
  return Math.max(1, Math.min(10, rounded));
}

function resolveRpcCall(path, upperMethod, body) {
  if (upperMethod === 'GET' && path === '/status') return { method: 'health', params: {} };
  if (upperMethod === 'GET' && path === '/session.status') return { method: 'sessions.list', params: {} };
  if (upperMethod === 'GET' && path === '/subagents.list') return { method: 'agents.list', params: {} };
  if (upperMethod === 'GET' && path === '/nodes.status') return { method: 'node.list', params: {} };
  if (upperMethod === 'GET' && path === '/tts.status') return { method: 'tts.status', params: {} };
  if (upperMethod === 'GET' && path === '/config.get') return { method: 'config.get', params: {} };

  if (upperMethod === 'POST' && path === '/spawn') {
    const sessionKey = normalizeSessionKey(body?.sessionKey);
    const message = typeof body?.task === 'string' && body.task.trim()
      ? body.task.trim()
      : 'Quick assistance';
    return {
      method: 'chat.send',
      params: {
        sessionKey,
        message,
        deliver: body?.deliver !== false,
        idempotencyKey: `sd-spawn-${Date.now()}-${Math.random().toString(36).slice(2, 8)}`
      }
    };
  }

  if (upperMethod === 'POST' && path === '/web.search') {
    const sessionKey = normalizeSessionKey(body?.sessionKey);
    const query = typeof body?.query === 'string' && body.query.trim()
      ? body.query.trim()
      : 'latest openclaw updates';
    const count = normalizeSearchCount(body?.count);
    const message = typeof body?.prompt === 'string' && body.prompt.trim()
      ? body.prompt.trim()
      : `Search the web for "${query}" and return the top ${count} findings with sources.`;
    return {
      method: 'chat.send',
      params: {
        sessionKey,
        message,
        deliver: body?.deliver !== false,
        idempotencyKey: `sd-search-${Date.now()}-${Math.random().toString(36).slice(2, 8)}`
      }
    };
  }

  if (upperMethod === 'POST' && path === '/tts.enable') {
    return {
      method: 'tts.enable',
      params: {}
    };
  }

  if (upperMethod === 'POST' && path === '/tts.disable') {
    return {
      method: 'tts.disable',
      params: {}
    };
  }

  if (upperMethod === 'POST' && path === '/session.set') {
    const normalizedModel = normalizeModelId(body?.model);
    if (!normalizedModel) return null;
    return {
      method: 'sessions.patch',
      params: {
        key: DEFAULT_SESSION_KEY,
        model: normalizedModel
      }
    };
  }

  return null;
}

function getOpenClawCliJsPath() {
  const appData = process.env.APPDATA;
  if (!appData) return null;
  const cliJs = path.join(appData, 'npm', 'node_modules', 'openclaw', 'dist', 'index.js');
  return fs.existsSync(cliJs) ? cliJs : null;
}

async function invokeGatewayRpcViaCli({ gw, rpc, timeoutMs, log }) {
  const cliJs = getOpenClawCliJsPath();
  if (!cliJs) {
    throw new Error('OpenClaw CLI runtime not found');
  }

  const args = [
    cliJs,
    'gateway',
    'call',
    rpc.method,
    '--json',
    '--timeout',
    String(Math.max(1000, Math.floor(timeoutMs)))
  ];

  const paramsJson = JSON.stringify(rpc.params || {});
  args.push('--params', paramsJson);

  const wsUrl = toGatewayWsUrl(gw?.url);
  if (wsUrl) args.push('--url', wsUrl);
  if (gw?.token) args.push('--token', gw.token);

  const started = Date.now();
  try {
    const out = await execFileAsync(process.execPath, args, {
      windowsHide: true,
      maxBuffer: 10 * 1024 * 1024,
      timeout: Math.max(1500, Math.floor(timeoutMs) + 500)
    });

    const stdout = String(out?.stdout || '').trim();
    let data = {};
    if (stdout) {
      try {
        data = JSON.parse(stdout);
      } catch {
        data = { raw: stdout };
      }
    }

    return {
      ok: true,
      status: 200,
      data,
      gateway: gw.key,
      latencyMs: Date.now() - started
    };
  } catch (error) {
    const stderr = String(error?.stderr || '').trim();
    const stdout = String(error?.stdout || '').trim();
    const reason = stderr || stdout || String(error?.message || error);
    safeLog(log, 'warn', 'gateway.rpc_call_failed', {
      rpcMethod: rpc.method,
      reason
    });
    return {
      ok: false,
      status: 0,
      data: { error: reason, rpcMethod: rpc.method },
      gateway: gw.key,
      latencyMs: Date.now() - started
    };
  }
}

function isHtmlResponse(data) {
  const raw = typeof data?.raw === 'string' ? data.raw.trim().toLowerCase() : '';
  return raw.startsWith('<!doctype html') || raw.startsWith('<html');
}

async function invokeGatewayCall(params) {
  const upperMethod = String(params?.method || 'GET').toUpperCase();
  const body = params?.body;
  const timeoutMs = clampNumber(params?.timeoutMs, 250, 60000, 9000);
  const maxRetries = clampNumber(params?.maxRetries, 0, 8, 0);
  const retryBackoffMs = clampNumber(params?.retryBackoffMs, 50, 60000, 250);
  const errCode = params?.errCode;
  const recordTelemetry = params?.recordTelemetry;
  const log = typeof params?.log === 'function' ? params.log : (() => {});
  const fetchImpl = typeof params?.fetchImpl === 'function' ? params.fetchImpl : fetch;
  const rpcInvokeImpl = typeof params?.rpcInvokeImpl === 'function'
    ? params.rpcInvokeImpl
    : invokeGatewayRpcViaCli;
  const gw = normalizeGatewayInput(params?.gw);
  const path = normalizeGatewayPath(params?.path);
  const action = `${upperMethod} ${path || '<invalid>'}`;

  if (!gw || !path) {
    const result = makeFailureResult({
      gatewayKey: gw?.key || params?.gw?.key || 'default',
      error: !gw ? 'Invalid gateway configuration' : 'Invalid gateway path'
    });
    const code = safeErrCode(errCode, result);
    safeRecordTelemetry(recordTelemetry, action, 'err', 0, code, {
      path: path || null,
      method: upperMethod,
      attempts: 1,
      invalidInput: true
    }, log);
    return result;
  }

  const preferRpc = typeof params?.fetchImpl !== 'function';
  const rpcCall = preferRpc ? resolveRpcCall(path, upperMethod, body) : null;

  let final;
  try {
    final = await executeWithRetry({
      maxRetries,
      baseBackoffMs: retryBackoffMs,
      maxBackoffMs: Math.max(retryBackoffMs, 10000),
      operation: async ({ attempt, maxAttempts }) => {
        safeLog(log, 'info', 'gateway.call_start', {
          method: upperMethod,
          path,
          gateway: gw.key,
          attempt,
          maxAttempts
        });

        const ac = new AbortController();
        const timer = setTimeout(() => ac.abort(), timeoutMs);
        const started = Date.now();
        try {
          if (rpcCall) {
            const rpcResult = await rpcInvokeImpl({
              gw,
              rpc: rpcCall,
              timeoutMs,
              log
            });
            return {
              ...rpcResult,
              attempt,
              maxAttempts
            };
          }

          const hasBody = body !== undefined && body !== null && upperMethod !== 'GET' && upperMethod !== 'HEAD';
          const headers = { accept: 'application/json' };
          if (hasBody) headers['content-type'] = 'application/json';
          if (gw.token) headers.authorization = `Bearer ${gw.token}`;
          const req = {
            method: upperMethod,
            headers,
            signal: ac.signal
          };
          if (hasBody) req.body = JSON.stringify(body);

          const r = await fetchImpl(`${gw.url}${path}`, req);
          const latencyMs = Date.now() - started;
          const text = await r.text();
          let data = {};
          if (text) {
            try {
              data = JSON.parse(text);
            } catch {
              data = { raw: text };
            }
          }

          if (r.ok && isHtmlResponse(data) && rpcCall) {
            // OpenClaw gateway port serves dashboard HTML; retry with RPC transport.
            const rpcResult = await rpcInvokeImpl({
              gw,
              rpc: rpcCall,
              timeoutMs,
              log
            });
            return {
              ...rpcResult,
              attempt,
              maxAttempts
            };
          }

          return { ok: r.ok, status: r.status, data, gateway: gw.key, latencyMs, attempt, maxAttempts };
        } catch (e) {
          const latencyMs = Date.now() - started;
          const timeoutError = e && e.name === 'AbortError';
          const message = timeoutError ? `Request timed out after ${timeoutMs}ms` : String(e);
          return {
            ok: false,
            status: 0,
            data: { error: message },
            gateway: gw.key,
            latencyMs,
            attempt,
            maxAttempts
          };
        } finally {
          clearTimeout(timer);
        }
      },
      shouldRetry: ({ result, attempt, maxAttempts, error }) => shouldRetryGatewayResult(result, attempt, maxAttempts, error),
      onRetry: async ({ attempt, backoffMs, result, error }) => {
        if (result) {
          safeLog(log, 'warn', 'gateway.call_retrying', { method: upperMethod, path, gateway: gw.key, attempt, status: result.status, backoffMs });
        } else {
          safeLog(log, 'warn', 'gateway.call_retrying', { method: upperMethod, path, gateway: gw.key, attempt, error: String(error), backoffMs });
        }
      }
    });
  } catch (error) {
    final = {
      result: makeFailureResult({
        gatewayKey: gw.key,
        error,
        latencyMs: 0,
        attempt: maxRetries + 1,
        maxAttempts: maxRetries + 1
      }),
      attempt: maxRetries + 1
    };
  }

  const result = final?.result || makeFailureResult({
    gatewayKey: gw.key,
    error: 'Unknown gateway error',
    latencyMs: 0,
    attempt: maxRetries + 1,
    maxAttempts: maxRetries + 1
  });

  const attempts = Number(result.attempt || final?.attempt || 1);
  const code = result.ok ? 'OK' : safeErrCode(errCode, result);
  safeLog(log, 'info', 'gateway.call_done', {
    method: upperMethod,
    path,
    gateway: gw.key,
    ok: result.ok,
    status: Number(result.status || 0),
    attempts
  });
  safeRecordTelemetry(recordTelemetry, action, result.ok ? 'ok' : 'err', result.latencyMs || 0, code, {
    path,
    method: upperMethod,
    attempts
  }, log);
  return result;
}

module.exports = { invokeGatewayCall };
