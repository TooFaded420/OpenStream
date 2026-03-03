const test = require('node:test');
const assert = require('node:assert/strict');
const http = require('http');
const { chooseGatewayKey } = require('../lib/routing');
const { invokeGatewayCall } = require('../lib/gateway-call');

function startGatewayServer({ statusCode = 200, latencyMs = 0, nodes = 1 }) {
  const server = http.createServer(async (req, res) => {
    if (latencyMs > 0) {
      await new Promise(resolve => setTimeout(resolve, latencyMs));
    }
    if (req.url === '/status') {
      res.writeHead(statusCode, { 'content-type': 'application/json' });
      res.end(JSON.stringify({ ok: statusCode === 200 }));
      return;
    }
    if (req.url === '/nodes.status') {
      res.writeHead(statusCode, { 'content-type': 'application/json' });
      res.end(JSON.stringify({ nodes: Array.from({ length: nodes }, (_, i) => ({ id: `n${i}` })) }));
      return;
    }
    res.writeHead(404, { 'content-type': 'application/json' });
    res.end('{}');
  });
  return new Promise(resolve => {
    server.listen(0, '127.0.0.1', () => {
      const addr = server.address();
      resolve({
        server,
        url: `http://127.0.0.1:${addr.port}`
      });
    });
  });
}

test('virtual multi-gateway routing chooses latency_best and executes call', async () => {
  const g1 = await startGatewayServer({ statusCode: 200, latencyMs: 60, nodes: 1 });
  const g2 = await startGatewayServer({ statusCode: 200, latencyMs: 10, nodes: 4 });
  const g3 = await startGatewayServer({ statusCode: 503, latencyMs: 0, nodes: 0 });

  try {
    const health = {
      gw1: { ok: true, latencyMs: 60 },
      gw2: { ok: true, latencyMs: 10 },
      gw3: { ok: false, latencyMs: 0 }
    };
    const key = chooseGatewayKey({
      mode: 'latency_best',
      activeGatewayKey: 'gw1',
      availableGatewayKeys: ['gw1', 'gw2', 'gw3'],
      healthByGateway: health,
      action: 'com.openclaw.v5.status',
      roleGatewayMap: {}
    });
    assert.equal(key, 'gw2');

    const urls = { gw1: g1.url, gw2: g2.url, gw3: g3.url };
    const telemetry = [];
    const result = await invokeGatewayCall({
      gw: { key, url: urls[key], token: null },
      path: '/status',
      method: 'GET',
      fetchImpl: fetch,
      timeoutMs: 1000,
      maxRetries: 0,
      retryBackoffMs: 1,
      errCode: () => 'ERR',
      recordTelemetry: (action, status, latencyMs, code, details) => telemetry.push({ action, status, latencyMs, code, details }),
      log: () => {}
    });
    assert.equal(result.ok, true);
    assert.equal(telemetry.length, 1);
    assert.equal(telemetry[0].status, 'ok');
  } finally {
    await Promise.all([
      new Promise(resolve => g1.server.close(resolve)),
      new Promise(resolve => g2.server.close(resolve)),
      new Promise(resolve => g3.server.close(resolve))
    ]);
  }
});
