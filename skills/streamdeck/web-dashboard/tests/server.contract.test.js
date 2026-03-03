const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('fs');
const os = require('os');
const path = require('path');

const { createServer } = require('../server');

function mkTempFixtureDir() {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'openclaw-streamdeck-'));
  fs.writeFileSync(path.join(dir, 'index.html'), '<html><body>index</body></html>', 'utf8');
  fs.writeFileSync(path.join(dir, 'wizard.html'), '<html><body>wizard</body></html>', 'utf8');
  return dir;
}

async function withServer(fn) {
  const fixtureDir = mkTempFixtureDir();
  const cfgPath = path.join(fixtureDir, 'streamdeck-gateways.json');
  const deviceMapPath = path.join(fixtureDir, 'streamdeck-device-map.json');
  const openclawCfgPath = path.join(fixtureDir, 'openclaw.json');
  fs.writeFileSync(deviceMapPath, JSON.stringify({ deck1: 'main' }, null, 2), 'utf8');
  fs.writeFileSync(openclawCfgPath, JSON.stringify({
    gateways: {
      lab: { url: 'http://192.168.1.40:18790', token: 'tok-a' },
      backup: { url: 'http://192.168.1.41:18790' }
    }
  }, null, 2), 'utf8');

  const server = createServer({
    port: 0,
    rootDir: fixtureDir,
    gatewayCfgPath: cfgPath,
    deviceMapPath,
    openclawCfgPath,
    testGatewayFn: async (url) => {
      if (String(url).includes(':18790')) {
        return { ok: true, code: 'OK', latencyMs: 5 };
      }
      return { ok: false, code: 'OFF', latencyMs: null };
    }
  });

  await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
  const addr = server.address();
  const baseUrl = `http://127.0.0.1:${addr.port}`;

  try {
    await fn({ baseUrl, cfgPath });
  } finally {
    await new Promise(resolve => server.close(resolve));
    fs.rmSync(fixtureDir, { recursive: true, force: true });
  }
}

test('GET /api/health returns ok and security headers', async () => {
  await withServer(async ({ baseUrl }) => {
    const res = await fetch(`${baseUrl}/api/health`);
    assert.equal(res.status, 200);
    const body = await res.json();
    assert.equal(body.ok, true);
    assert.ok(Number.isInteger(body.uptimeSec));
    assert.equal(res.headers.get('x-content-type-options'), 'nosniff');
    assert.equal(res.headers.get('x-frame-options'), 'SAMEORIGIN');
    assert.equal(res.headers.get('cache-control'), 'no-store');
  });
});

test('GET and POST /api/gateway-config roundtrip persists config', async () => {
  await withServer(async ({ baseUrl, cfgPath }) => {
    const initial = await fetch(`${baseUrl}/api/gateway-config`);
    assert.equal(initial.status, 200);
    const initialBody = await initial.json();
    assert.equal(initialBody.active, 'origin-main');

    const payload = {
      active: 'lab',
      gateways: {
        lab: { url: 'http://127.0.0.1:28790', token: 'abc' }
      }
    };
    const saveRes = await fetch(`${baseUrl}/api/gateway-config`, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify(payload)
    });
    assert.equal(saveRes.status, 200);

    const reloaded = JSON.parse(fs.readFileSync(cfgPath, 'utf8'));
    assert.equal(reloaded.active, 'lab');
    assert.equal(reloaded.gateways.lab.url, 'http://127.0.0.1:28790');
  });
});

test('POST /api/gateway-config rejects malformed JSON', async () => {
  await withServer(async ({ baseUrl }) => {
    const res = await fetch(`${baseUrl}/api/gateway-config`, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: '{"active":'
    });
    assert.equal(res.status, 400);
    const body = await res.text();
    assert.ok(body.includes('Bad JSON'));
  });
});

test('method restrictions return 405', async () => {
  await withServer(async ({ baseUrl }) => {
    const res = await fetch(`${baseUrl}/api/gateway-config`, { method: 'DELETE' });
    assert.equal(res.status, 405);
  });
});

test('POST /api/detect-local adds healthy local gateway', async () => {
  await withServer(async ({ baseUrl }) => {
    const res = await fetch(`${baseUrl}/api/detect-local`, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ host: '127.0.0.1', ports: ['18790', '29999'] })
    });
    assert.equal(res.status, 200);
    const body = await res.json();
    assert.ok(body.gateways['origin-main']);
    assert.equal(body.gateways['origin-main'].url, 'http://127.0.0.1:18790');
  });
});

test('POST /api/gateway-upsert adds gateway and persists normalized name', async () => {
  await withServer(async ({ baseUrl }) => {
    const res = await fetch(`${baseUrl}/api/gateway-upsert`, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ name: 'Lab Node A', url: 'http://10.0.0.22:18790', token: 'abc' })
    });
    assert.equal(res.status, 200);
    const body = await res.json();
    assert.ok(body.gateways['lab-node-a']);
    assert.equal(body.gateways['lab-node-a'].url, 'http://10.0.0.22:18790');
    assert.equal(body.gateways['lab-node-a'].token, 'abc');
  });
});

test('POST /api/discover-hosts scans host list and merges healthy gateways', async () => {
  await withServer(async ({ baseUrl }) => {
    const res = await fetch(`${baseUrl}/api/discover-hosts`, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ hosts: ['192.168.1.148'], ports: ['18790', '19999'] })
    });
    assert.equal(res.status, 200);
    const body = await res.json();
    assert.ok(body.config.gateways['192.168.1.148-18790']);
    assert.equal(Array.isArray(body.discovered), true);
    assert.equal(body.discovered.length, 1);
  });
});

test('POST /api/import-openclaw imports gateway candidates from openclaw config', async () => {
  await withServer(async ({ baseUrl }) => {
    const res = await fetch(`${baseUrl}/api/import-openclaw`, {
      method: 'POST'
    });
    assert.equal(res.status, 200);
    const body = await res.json();
    assert.equal(body.imported >= 2, true);
    assert.equal(body.config.gateways.lab.url, 'http://192.168.1.40:18790');
  });
});

test('POST /api/discover-sweep starts job and status endpoint returns progress', async () => {
  await withServer(async ({ baseUrl }) => {
    const start = await fetch(`${baseUrl}/api/discover-sweep`, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ subnet: '127.0.0.1-2', ports: ['18790'] })
    });
    assert.equal(start.status, 200);
    const startBody = await start.json();
    assert.equal(startBody.ok, true);
    assert.ok(startBody.job.id);

    const status = await fetch(`${baseUrl}/api/discover-sweep/${encodeURIComponent(startBody.job.id)}`);
    assert.equal(status.status, 200);
    const statusBody = await status.json();
    assert.equal(statusBody.ok, true);
    assert.ok(['running', 'completed', 'cancelling', 'cancelled'].includes(statusBody.job.status));
  });
});

test('POST /api/discover-sweep/:id/cancel accepts cancellation request', async () => {
  await withServer(async ({ baseUrl }) => {
    const start = await fetch(`${baseUrl}/api/discover-sweep`, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ subnet: '127.0.0.1-20', ports: ['18790'] })
    });
    const startBody = await start.json();
    const jobId = startBody.job.id;

    const cancel = await fetch(`${baseUrl}/api/discover-sweep/${encodeURIComponent(jobId)}/cancel`, {
      method: 'POST'
    });
    assert.equal(cancel.status, 200);
    const cancelBody = await cancel.json();
    assert.equal(cancelBody.ok, true);
    assert.equal(cancelBody.job.cancelled, true);
  });
});
