const test = require('node:test');
const assert = require('node:assert/strict');
const { invokeGatewayCall } = require('../lib/gateway-call');

function makeResponse(status, bodyObj) {
  return {
    ok: status >= 200 && status < 300,
    status,
    async text() {
      return JSON.stringify(bodyObj || {});
    }
  };
}

test('GET retries transient error and succeeds, telemetry records attempts', async () => {
  const calls = [];
  const telemetry = [];
  const fetchImpl = async () => {
    calls.push('x');
    if (calls.length === 1) return makeResponse(503, { error: 'unavailable' });
    return makeResponse(200, { ok: true });
  };

  const result = await invokeGatewayCall({
    gw: { key: 'default', url: 'http://127.0.0.1:18790', token: null },
    path: '/status',
    method: 'GET',
    timeoutMs: 500,
    maxRetries: 2,
    retryBackoffMs: 1,
    fetchImpl,
    errCode: () => 'ERR',
    recordTelemetry: (action, status, latencyMs, code, details) => telemetry.push({ action, status, latencyMs, code, details }),
    log: () => {}
  });

  assert.equal(result.ok, true);
  assert.equal(result.attempt, 2);
  assert.equal(calls.length, 2);
  assert.equal(telemetry.length, 1);
  assert.equal(telemetry[0].action, 'GET /status');
  assert.equal(telemetry[0].status, 'ok');
  assert.equal(telemetry[0].code, 'OK');
  assert.equal(telemetry[0].details.attempts, 2);
});

test('POST with zero retries does not retry on 503', async () => {
  let calls = 0;
  const telemetry = [];
  const fetchImpl = async () => {
    calls++;
    return makeResponse(503, { error: 'down' });
  };

  const result = await invokeGatewayCall({
    gw: { key: 'default', url: 'http://127.0.0.1:18790', token: null },
    path: '/spawn',
    method: 'POST',
    body: { task: 'x' },
    timeoutMs: 500,
    maxRetries: 0,
    retryBackoffMs: 1,
    fetchImpl,
    errCode: (r) => (r.status === 503 ? 'ERR' : 'OFF'),
    recordTelemetry: (action, status, latencyMs, code, details) => telemetry.push({ action, status, latencyMs, code, details }),
    log: () => {}
  });

  assert.equal(calls, 1);
  assert.equal(result.ok, false);
  assert.equal(result.status, 503);
  assert.equal(telemetry[0].status, 'err');
  assert.equal(telemetry[0].details.attempts, 1);
});

test('network exception retries and then succeeds', async () => {
  let calls = 0;
  const telemetry = [];
  const fetchImpl = async () => {
    calls++;
    if (calls === 1) throw new Error('socket hang up');
    return makeResponse(200, { model: 'ok' });
  };

  const result = await invokeGatewayCall({
    gw: { key: 'default', url: 'http://127.0.0.1:18790', token: null },
    path: '/session.status',
    method: 'GET',
    timeoutMs: 500,
    maxRetries: 1,
    retryBackoffMs: 1,
    fetchImpl,
    errCode: () => 'OFF',
    recordTelemetry: (action, status, latencyMs, code, details) => telemetry.push({ action, status, latencyMs, code, details }),
    log: () => {}
  });

  assert.equal(result.ok, true);
  assert.equal(result.attempt, 2);
  assert.equal(calls, 2);
  assert.equal(telemetry.length, 1);
  assert.equal(telemetry[0].status, 'ok');
  assert.equal(telemetry[0].details.attempts, 2);
});

test('normalizes relative paths and applies auth header', async () => {
  let seenUrl = null;
  let seenOptions = null;

  const result = await invokeGatewayCall({
    gw: { key: 'default', url: 'http://127.0.0.1:18790', token: 'secret-token' },
    path: 'status',
    method: 'GET',
    body: { ignored: true },
    timeoutMs: 500,
    maxRetries: 0,
    retryBackoffMs: 1,
    fetchImpl: async (url, options) => {
      seenUrl = url;
      seenOptions = options;
      return makeResponse(200, { ok: true });
    },
    errCode: () => 'ERR',
    recordTelemetry: () => {},
    log: () => {}
  });

  assert.equal(result.ok, true);
  assert.equal(seenUrl, 'http://127.0.0.1:18790/status');
  assert.equal(seenOptions.headers.authorization, 'Bearer secret-token');
  assert.equal(seenOptions.body, undefined);
});

test('rejects absolute URL path input and skips network call', async () => {
  let calls = 0;
  const telemetry = [];

  const result = await invokeGatewayCall({
    gw: { key: 'default', url: 'http://127.0.0.1:18790', token: null },
    path: 'https://example.com/status',
    method: 'GET',
    timeoutMs: 500,
    maxRetries: 0,
    retryBackoffMs: 1,
    fetchImpl: async () => {
      calls++;
      return makeResponse(200, { ok: true });
    },
    errCode: () => 'ERR',
    recordTelemetry: (action, status, latencyMs, code, details) => telemetry.push({ action, status, latencyMs, code, details }),
    log: () => {}
  });

  assert.equal(calls, 0);
  assert.equal(result.ok, false);
  assert.equal(result.status, 0);
  assert.equal(telemetry.length, 1);
  assert.equal(telemetry[0].details.invalidInput, true);
});

test('telemetry callback failure does not fail gateway call', async () => {
  const result = await invokeGatewayCall({
    gw: { key: 'default', url: 'http://127.0.0.1:18790', token: null },
    path: '/status',
    method: 'GET',
    timeoutMs: 500,
    maxRetries: 0,
    retryBackoffMs: 1,
    fetchImpl: async () => makeResponse(200, { ok: true }),
    errCode: () => 'ERR',
    recordTelemetry: () => {
      throw new Error('telemetry write failed');
    },
    log: () => {}
  });

  assert.equal(result.ok, true);
  assert.equal(result.status, 200);
});

test('uses RPC transport for /status when fetchImpl is not provided', async () => {
  const telemetry = [];
  const rpcCalls = [];
  const result = await invokeGatewayCall({
    gw: { key: 'default', url: 'http://127.0.0.1:18790', token: 't1' },
    path: '/status',
    method: 'GET',
    timeoutMs: 500,
    maxRetries: 0,
    retryBackoffMs: 1,
    rpcInvokeImpl: async ({ rpc, gw }) => {
      rpcCalls.push({ rpc, gw });
      return { ok: true, status: 200, data: { ok: true }, gateway: gw.key, latencyMs: 12 };
    },
    errCode: () => 'ERR',
    recordTelemetry: (action, status, latencyMs, code, details) => telemetry.push({ action, status, latencyMs, code, details }),
    log: () => {}
  });

  assert.equal(result.ok, true);
  assert.equal(rpcCalls.length, 1);
  assert.equal(rpcCalls[0].rpc.method, 'health');
  assert.deepEqual(rpcCalls[0].rpc.params, {});
  assert.equal(telemetry.length, 1);
  assert.equal(telemetry[0].status, 'ok');
});

test('maps /session.set model payload to sessions.patch RPC', async () => {
  const rpcCalls = [];
  const result = await invokeGatewayCall({
    gw: { key: 'default', url: 'http://127.0.0.1:18790', token: 't1' },
    path: '/session.set',
    method: 'POST',
    body: { model: 'synthetic/hf:nvidia/Kimi-K2.5-NVFP4' },
    timeoutMs: 500,
    maxRetries: 0,
    retryBackoffMs: 1,
    rpcInvokeImpl: async ({ rpc, gw }) => {
      rpcCalls.push({ rpc, gw });
      return { ok: true, status: 200, data: { ok: true }, gateway: gw.key, latencyMs: 14 };
    },
    errCode: () => 'ERR',
    recordTelemetry: () => {},
    log: () => {}
  });

  assert.equal(result.ok, true);
  assert.equal(rpcCalls.length, 1);
  assert.equal(rpcCalls[0].rpc.method, 'sessions.patch');
  assert.equal(rpcCalls[0].rpc.params.key, 'agent:main:main');
  assert.equal(rpcCalls[0].rpc.params.model, 'synthetic/hf:nvidia/kimi-k2.5-nvfp4');
});

test('maps /spawn to chat.send RPC with session override', async () => {
  const rpcCalls = [];
  const result = await invokeGatewayCall({
    gw: { key: 'default', url: 'http://127.0.0.1:18790', token: 't1' },
    path: '/spawn',
    method: 'POST',
    body: { task: 'Quick assistance', sessionKey: 'agent:ops:main' },
    timeoutMs: 500,
    maxRetries: 0,
    retryBackoffMs: 1,
    rpcInvokeImpl: async ({ rpc, gw }) => {
      rpcCalls.push({ rpc, gw });
      return { ok: true, status: 200, data: { status: 'started' }, gateway: gw.key, latencyMs: 18 };
    },
    errCode: () => 'ERR',
    recordTelemetry: () => {},
    log: () => {}
  });

  assert.equal(result.ok, true);
  assert.equal(rpcCalls.length, 1);
  assert.equal(rpcCalls[0].rpc.method, 'chat.send');
  assert.equal(rpcCalls[0].rpc.params.sessionKey, 'agent:ops:main');
  assert.equal(rpcCalls[0].rpc.params.message, 'Quick assistance');
  assert.equal(rpcCalls[0].rpc.params.deliver, true);
  assert.ok(String(rpcCalls[0].rpc.params.idempotencyKey).startsWith('sd-spawn-'));
});

test('maps /web.search to chat.send RPC with templated prompt and capped count', async () => {
  const rpcCalls = [];
  const result = await invokeGatewayCall({
    gw: { key: 'default', url: 'http://127.0.0.1:18790', token: 't1' },
    path: '/web.search',
    method: 'POST',
    body: { query: 'openclaw stream deck', count: 25, sessionKey: 'agent:main:main' },
    timeoutMs: 500,
    maxRetries: 0,
    retryBackoffMs: 1,
    rpcInvokeImpl: async ({ rpc, gw }) => {
      rpcCalls.push({ rpc, gw });
      return { ok: true, status: 200, data: { status: 'started' }, gateway: gw.key, latencyMs: 16 };
    },
    errCode: () => 'ERR',
    recordTelemetry: () => {},
    log: () => {}
  });

  assert.equal(result.ok, true);
  assert.equal(rpcCalls.length, 1);
  assert.equal(rpcCalls[0].rpc.method, 'chat.send');
  assert.equal(rpcCalls[0].rpc.params.sessionKey, 'agent:main:main');
  assert.equal(rpcCalls[0].rpc.params.deliver, true);
  assert.equal(rpcCalls[0].rpc.params.message, 'Search the web for "openclaw stream deck" and return the top 10 findings with sources.');
  assert.ok(String(rpcCalls[0].rpc.params.idempotencyKey).startsWith('sd-search-'));
});

test('maps /tts.enable and /tts.disable to RPC methods', async () => {
  const rpcCalls = [];
  const rpcInvokeImpl = async ({ rpc, gw }) => {
    rpcCalls.push({ rpc, gw });
    return { ok: true, status: 200, data: { enabled: rpc.method === 'tts.enable' }, gateway: gw.key, latencyMs: 10 };
  };

  const enable = await invokeGatewayCall({
    gw: { key: 'default', url: 'http://127.0.0.1:18790', token: 't1' },
    path: '/tts.enable',
    method: 'POST',
    timeoutMs: 500,
    maxRetries: 0,
    retryBackoffMs: 1,
    rpcInvokeImpl,
    errCode: () => 'ERR',
    recordTelemetry: () => {},
    log: () => {}
  });
  const disable = await invokeGatewayCall({
    gw: { key: 'default', url: 'http://127.0.0.1:18790', token: 't1' },
    path: '/tts.disable',
    method: 'POST',
    timeoutMs: 500,
    maxRetries: 0,
    retryBackoffMs: 1,
    rpcInvokeImpl,
    errCode: () => 'ERR',
    recordTelemetry: () => {},
    log: () => {}
  });

  assert.equal(enable.ok, true);
  assert.equal(disable.ok, true);
  assert.equal(rpcCalls.length, 2);
  assert.equal(rpcCalls[0].rpc.method, 'tts.enable');
  assert.deepEqual(rpcCalls[0].rpc.params, {});
  assert.equal(rpcCalls[1].rpc.method, 'tts.disable');
  assert.deepEqual(rpcCalls[1].rpc.params, {});
});
