const http = require('http');
const fs = require('fs');
const path = require('path');

const MAX_BODY_BYTES = 1024 * 1024; // 1MB

function log(level, event, meta = {}) {
  const entry = {
    ts: new Date().toISOString(),
    level,
    event,
    ...meta
  };
  const line = JSON.stringify(entry);
  if (level === 'error') console.error(line);
  else if (level === 'warn') console.warn(line);
  else console.log(line);
}

function readText(p) {
  return fs.existsSync(p) ? fs.readFileSync(p, 'utf8') : '';
}

function json(res, obj) {
  const s = JSON.stringify(obj, null, 2);
  res.writeHead(200, { 'content-type': 'application/json; charset=utf-8' });
  res.end(s);
}

function text(res, s, code = 200, type = 'text/plain') {
  res.writeHead(code, { 'content-type': `${type}; charset=utf-8` });
  res.end(s);
}

function applySecurityHeaders(res) {
  res.setHeader('X-Content-Type-Options', 'nosniff');
  res.setHeader('X-Frame-Options', 'SAMEORIGIN');
  res.setHeader('Referrer-Policy', 'no-referrer');
  res.setHeader('Cache-Control', 'no-store');
}

function badRequest(res, message) {
  text(res, message, 400);
}

function methodNotAllowed(res) {
  text(res, 'Method Not Allowed', 405);
}

function parseJsonBody(req) {
  return new Promise((resolve, reject) => {
    let body = '';
    let received = 0;

    req.on('data', chunk => {
      received += chunk.length;
      if (received > MAX_BODY_BYTES) {
        req.destroy();
        reject(new Error('Payload too large'));
        return;
      }
      body += chunk;
    });

    req.on('end', () => {
      if (!body) {
        resolve({});
        return;
      }
      try {
        resolve(JSON.parse(body));
      } catch (e) {
        reject(new Error(`Bad JSON: ${e.message}`));
      }
    });

    req.on('error', reject);
  });
}

function sanitizeGatewayName(input, fallback = 'gateway') {
  const raw = String(input || '').trim().toLowerCase();
  const cleaned = raw.replace(/[^a-z0-9._-]+/g, '-').replace(/^-+|-+$/g, '');
  return cleaned || fallback;
}

function normalizeGatewayEntry(entry) {
  if (!entry || typeof entry !== 'object') return null;
  const url = typeof entry.url === 'string' ? entry.url.trim().replace(/\/$/, '') : '';
  if (!url) return null;
  try {
    const parsed = new URL(url);
    if (parsed.protocol !== 'http:' && parsed.protocol !== 'https:') return null;
  } catch {
    return null;
  }
  const token = typeof entry.token === 'string' && entry.token.trim() ? entry.token.trim() : null;
  return { url, token };
}

function normalizeGatewayConfig(input) {
  const out = { active: 'origin-main', gateways: {}, routeRoles: {} };
  const gateways = input && typeof input.gateways === 'object' ? input.gateways : {};
  for (const [rawKey, rawEntry] of Object.entries(gateways)) {
    const key = sanitizeGatewayName(rawKey);
    const entry = normalizeGatewayEntry(rawEntry);
    if (!key || !entry) continue;
    out.gateways[key] = entry;
  }
  if (!Object.keys(out.gateways).length) {
    out.gateways['origin-main'] = { url: 'http://127.0.0.1:18790', token: null };
  }
  const keys = Object.keys(out.gateways);
  out.active = typeof input?.active === 'string' && out.gateways[input.active] ? input.active : keys[0];
  const fallback = out.active;
  const routeRoles = input && typeof input.routeRoles === 'object' ? input.routeRoles : {};
  for (const role of ['default', 'audio', 'research', 'agents', 'session', 'nodes']) {
    const roleGw = typeof routeRoles[role] === 'string' && out.gateways[routeRoles[role]] ? routeRoles[role] : fallback;
    out.routeRoles[role] = roleGw;
  }
  return out;
}

function tryReadJson(filePath) {
  try {
    if (!fs.existsSync(filePath)) return null;
    const raw = fs.readFileSync(filePath, 'utf8').replace(/^\uFEFF/, '');
    return JSON.parse(raw);
  } catch {
    return null;
  }
}

function extractGatewayCandidates(input, parentKey = 'gateway') {
  const candidates = [];
  function walk(node, hint) {
    if (Array.isArray(node)) {
      for (let i = 0; i < node.length; i += 1) {
        walk(node[i], `${hint}-${i + 1}`);
      }
      return;
    }
    if (!node || typeof node !== 'object') return;

    const url = typeof node.url === 'string' ? node.url.trim() : '';
    if (url) {
      const token =
        typeof node.token === 'string' ? node.token :
        typeof node.authToken === 'string' ? node.authToken :
        typeof node.apiToken === 'string' ? node.apiToken :
        null;
      const nameHint =
        typeof node.name === 'string' && node.name.trim() ? node.name :
        typeof node.id === 'string' && node.id.trim() ? node.id :
        hint;
      candidates.push({
        key: sanitizeGatewayName(nameHint, hint),
        entry: { url, token: token && token.trim() ? token.trim() : null }
      });
    }

    for (const [k, v] of Object.entries(node)) {
      walk(v, sanitizeGatewayName(k, hint));
    }
  }
  walk(input, sanitizeGatewayName(parentKey));
  return candidates;
}

function parseSubnetRange(input) {
  const raw = String(input || '').trim();
  const match = /^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})\s*-\s*(\d{1,3})$/.exec(raw);
  if (!match) return null;
  const a = Number(match[1]);
  const b = Number(match[2]);
  const c = Number(match[3]);
  const start = Number(match[4]);
  const end = Number(match[5]);
  const octets = [a, b, c, start, end];
  if (octets.some(n => !Number.isInteger(n) || n < 0 || n > 255)) return null;
  if (start > end) return null;
  const hosts = [];
  for (let i = start; i <= end; i += 1) {
    hosts.push(`${a}.${b}.${c}.${i}`);
  }
  return hosts;
}

async function runPool(items, worker, concurrency) {
  const limit = Math.max(1, Math.min(64, Number(concurrency) || 8));
  const queue = [...items];
  const runners = new Array(limit).fill(null).map(async () => {
    while (queue.length) {
      const item = queue.shift();
      if (!item) continue;
      await worker(item);
    }
  });
  await Promise.all(runners);
}

async function testGateway(url, token) {
  const started = Date.now();
  try {
    const headers = token ? { Authorization: `Bearer ${token}` } : {};
    const r = await fetch(`${url}/status`, { headers, signal: AbortSignal.timeout(3000) });
    if (!r.ok) {
      const code = (r.status === 401 || r.status === 403) ? 'AUTH' : 'ERR';
      return { ok: false, code, latencyMs: null };
    }
    return { ok: true, code: 'OK', latencyMs: Date.now() - started };
  } catch (e) {
    const m = String(e.message || '').toLowerCase();
    const code = m.includes('timeout') || m.includes('aborted') ? 'TIME' : 'OFF';
    return { ok: false, code, latencyMs: null };
  }
}

function createServer(options = {}) {
  const port = Number(options.port || process.argv[2] || 8888);
  const rootDir = options.rootDir || __dirname;
  const homeDir = options.homeDir || process.env.USERPROFILE || process.env.HOME;
  const gatewayCfgPath = options.gatewayCfgPath || path.join(homeDir, '.openclaw', 'streamdeck-gateways.json');
  const openclawCfgPath = options.openclawCfgPath || path.join(homeDir, '.openclaw', 'openclaw.json');
  const deviceMapPath = options.deviceMapPath || path.join(homeDir, '.openclaw', 'streamdeck-device-map.json');
  const testGatewayFn = options.testGatewayFn || testGateway;
  const sweepJobs = new Map(); // id -> job state

  function loadCfg() {
    const parsed = tryReadJson(gatewayCfgPath);
    return normalizeGatewayConfig(parsed || {});
  }

  function saveCfg(cfg) {
    fs.mkdirSync(path.dirname(gatewayCfgPath), { recursive: true });
    fs.writeFileSync(gatewayCfgPath, JSON.stringify(normalizeGatewayConfig(cfg), null, 2));
  }

  function getSweepSummary(job) {
    return {
      id: job.id,
      status: job.status,
      subnet: job.subnet,
      startedAt: job.startedAt,
      endedAt: job.endedAt || null,
      total: job.total,
      scanned: job.scanned,
      healthy: job.healthy,
      discovered: job.discovered.slice(-50),
      cancelled: job.cancelled === true
    };
  }

  function startSweepJob(subnet, ports, concurrency) {
    const hosts = parseSubnetRange(subnet);
    if (!hosts || !hosts.length) {
      throw new Error('subnet must look like 192.168.1.1-254');
    }
    const cleanPorts = Array.isArray(ports)
      ? ports.map(v => String(v).trim()).filter(Boolean)
      : ['18790', '18789', '28790'];
    const job = {
      id: `${Date.now().toString(36)}-${Math.random().toString(36).slice(2, 8)}`,
      subnet,
      status: 'running',
      startedAt: Date.now(),
      endedAt: null,
      total: hosts.length * cleanPorts.length,
      scanned: 0,
      healthy: 0,
      discovered: [],
      cancelled: false
    };
    sweepJobs.set(job.id, job);

    const tasks = [];
    for (const host of hosts) {
      for (const port of cleanPorts) {
        tasks.push({ host, port });
      }
    }

    (async () => {
      try {
        await runPool(tasks, async ({ host, port }) => {
          if (job.cancelled) return;
          const url = `http://${host}:${port}`;
          const t = await testGatewayFn(url, null);
          job.scanned += 1;
          if (!t.ok) return;
          const key = sanitizeGatewayName(`${host}-${port}`, `gw-${port}`);
          job.healthy += 1;
          job.discovered.push({ key, url, latencyMs: t.latencyMs || null });
        }, concurrency);

        const cfg = normalizeGatewayConfig(loadCfg());
        const gateways = { ...cfg.gateways };
        for (const d of job.discovered) {
          gateways[d.key] = { url: d.url, token: gateways[d.key]?.token || null };
        }
        const out = normalizeGatewayConfig({ active: cfg.active, gateways, routeRoles: cfg.routeRoles });
        saveCfg(out);
        job.status = job.cancelled ? 'cancelled' : 'completed';
      } catch (e) {
        job.status = 'failed';
        job.error = e.message;
      } finally {
        job.endedAt = Date.now();
      }
    })();

    return job;
  }

  const server = http.createServer(async (req, res) => {
    applySecurityHeaders(res);
    try {
      const url = new URL(req.url, `http://localhost:${port}`);
      const p = url.pathname;
      log('info', 'http.request', { method: req.method, path: p });

      if (p === '/api/health') return json(res, { ok: true, uptimeSec: Math.round(process.uptime()) });

      if (p === '/' || p === '/index.html') {
        const html = readText(path.join(rootDir, 'index.html'));
        return html ? text(res, html, 200, 'text/html') : text(res, 'index.html missing', 500);
      }
      if (p === '/wizard' || p === '/wizard.html') {
        const html = readText(path.join(rootDir, 'wizard.html'));
        return html ? text(res, html, 200, 'text/html') : text(res, 'wizard.html missing', 500);
      }
      if (p === '/api/device-map') {
        try {
          return json(res, JSON.parse(readText(deviceMapPath) || '{}'));
        } catch {
          return json(res, {});
        }
      }

      if (p === '/api/gateway-config') {
        if (req.method === 'GET') return json(res, loadCfg());
        if (req.method !== 'POST') return methodNotAllowed(res);
        try {
          const cfg = normalizeGatewayConfig(await parseJsonBody(req));
          saveCfg(cfg);
          return json(res, loadCfg());
        } catch (e) {
          return badRequest(res, e.message);
        }
      }

      if (p === '/api/detect-local') {
        if (req.method !== 'POST') return methodNotAllowed(res);
        let body = {};
        try {
          body = await parseJsonBody(req);
        } catch (e) {
          return badRequest(res, e.message);
        }
        const cfg = normalizeGatewayConfig(loadCfg());
        let host = '127.0.0.1';
        let ports = ['18790', '18789', '28790'];
        if (typeof body.host === 'string' && body.host.trim()) host = body.host.trim();
        if (Array.isArray(body.ports)) ports = body.ports.map(String);
        const gateways = { ...(cfg.gateways || {}) };
        for (const pt of ports) {
          const name = pt === '18790' ? 'origin-main' : (pt === '18789' ? 'zero-mac' : `local-${pt}`);
          const checkUrl = `http://${host}:${pt}`;
          const t = await testGatewayFn(checkUrl, gateways[name]?.token || null);
          if (t.ok) gateways[name] = { url: checkUrl, token: gateways[name]?.token || null };
        }
        const out = normalizeGatewayConfig({ active: cfg.active, gateways, routeRoles: cfg.routeRoles });
        if (!out.gateways[out.active]) out.active = Object.keys(out.gateways)[0] || 'origin-main';
        saveCfg(out);
        return json(res, out);
      }

      if (p === '/api/discover-hosts') {
        if (req.method !== 'POST') return methodNotAllowed(res);
        let body = {};
        try {
          body = await parseJsonBody(req);
        } catch (e) {
          return badRequest(res, e.message);
        }
        const cfg = normalizeGatewayConfig(loadCfg());
        const hosts = Array.isArray(body.hosts) ? body.hosts.map(v => String(v).trim()).filter(Boolean) : [];
        const ports = Array.isArray(body.ports) ? body.ports.map(v => String(v).trim()).filter(Boolean) : ['18790', '18789', '28790'];
        if (!hosts.length) return badRequest(res, 'hosts is required');

        const gateways = { ...cfg.gateways };
        const discovered = [];
        for (const host of hosts) {
          for (const port of ports) {
            const url = `http://${host}:${port}`;
            const t = await testGatewayFn(url, null);
            if (!t.ok) continue;
            const key = sanitizeGatewayName(`${host}-${port}`, `gw-${port}`);
            gateways[key] = { url, token: gateways[key]?.token || null };
            discovered.push({ key, url, latencyMs: t.latencyMs || null });
          }
        }
        const out = normalizeGatewayConfig({ active: cfg.active, gateways, routeRoles: cfg.routeRoles });
        saveCfg(out);
        return json(res, { config: out, discovered });
      }

      if (p === '/api/discover-sweep') {
        if (req.method !== 'POST') return methodNotAllowed(res);
        let body = {};
        try {
          body = await parseJsonBody(req);
        } catch (e) {
          return badRequest(res, e.message);
        }
        try {
          const job = startSweepJob(body.subnet, body.ports, body.concurrency);
          return json(res, { ok: true, job: getSweepSummary(job) });
        } catch (e) {
          return badRequest(res, e.message);
        }
      }

      const sweepStatusMatch = /^\/api\/discover-sweep\/([^/]+)$/.exec(p);
      if (sweepStatusMatch) {
        const id = sweepStatusMatch[1];
        const job = sweepJobs.get(id);
        if (!job) return text(res, 'Sweep job not found', 404);
        if (req.method !== 'GET') return methodNotAllowed(res);
        const cfg = loadCfg();
        return json(res, { ok: true, job: getSweepSummary(job), active: cfg.active });
      }

      const sweepCancelMatch = /^\/api\/discover-sweep\/([^/]+)\/cancel$/.exec(p);
      if (sweepCancelMatch) {
        const id = sweepCancelMatch[1];
        const job = sweepJobs.get(id);
        if (!job) return text(res, 'Sweep job not found', 404);
        if (req.method !== 'POST') return methodNotAllowed(res);
        job.cancelled = true;
        if (job.status === 'running') job.status = 'cancelling';
        return json(res, { ok: true, job: getSweepSummary(job) });
      }

      if (p === '/api/gateway-upsert') {
        if (req.method !== 'POST') return methodNotAllowed(res);
        let body = {};
        try {
          body = await parseJsonBody(req);
        } catch (e) {
          return badRequest(res, e.message);
        }
        const key = sanitizeGatewayName(body.name, '');
        if (!key) return badRequest(res, 'name is required');
        const entry = normalizeGatewayEntry({ url: body.url, token: body.token });
        if (!entry) return badRequest(res, 'valid http/https url is required');
        const cfg = normalizeGatewayConfig(loadCfg());
        cfg.gateways[key] = entry;
        if (body.setActive === true) cfg.active = key;
        saveCfg(cfg);
        return json(res, normalizeGatewayConfig(loadCfg()));
      }

      if (p === '/api/import-openclaw') {
        if (req.method !== 'POST') return methodNotAllowed(res);
        const cfg = normalizeGatewayConfig(loadCfg());
        const src = tryReadJson(openclawCfgPath);
        if (!src) return badRequest(res, `OpenClaw config not found: ${openclawCfgPath}`);
        const candidates = extractGatewayCandidates(src, 'openclaw');
        if (!candidates.length) return badRequest(res, 'No gateway-like objects found in openclaw.json');

        const gateways = { ...cfg.gateways };
        let added = 0;
        for (const candidate of candidates) {
          const entry = normalizeGatewayEntry(candidate.entry);
          if (!entry) continue;
          let key = candidate.key || 'openclaw';
          if (gateways[key] && gateways[key].url !== entry.url) {
            let i = 2;
            while (gateways[`${key}-${i}`]) i += 1;
            key = `${key}-${i}`;
          }
          gateways[key] = entry;
          added += 1;
        }

        const out = normalizeGatewayConfig({ active: cfg.active, gateways, routeRoles: cfg.routeRoles });
        saveCfg(out);
        return json(res, { config: out, imported: added, source: openclawCfgPath });
      }

      if (p === '/api/test-gateways') {
        if (req.method !== 'GET') return methodNotAllowed(res);
        const cfg = loadCfg();
        const out = {};
        for (const [k, g] of Object.entries(cfg.gateways || {})) out[k] = await testGatewayFn(g.url, g.token);
        return json(res, out);
      }

      if (p === '/api/apply-best-gateway') {
        if (req.method !== 'POST') return methodNotAllowed(res);
        const cfg = loadCfg();
        let best = null;
        for (const [k, g] of Object.entries(cfg.gateways || {})) {
          const t = await testGatewayFn(g.url, g.token);
          if (t.ok && (!best || t.latencyMs < best.latencyMs)) best = { key: k, latencyMs: t.latencyMs };
        }
        if (!best) return json(res, { ok: false, error: 'No healthy gateways found' });
        cfg.active = best.key;
        saveCfg(cfg);
        return json(res, { ok: true, active: best.key, latencyMs: best.latencyMs });
      }

      return text(res, 'Not Found', 404);
    } catch (e) {
      log('error', 'http.unhandled', { error: e.message });
      return text(res, `Server error: ${e.message}`, 500);
    }
  });

  return server;
}

function startServer(options = {}) {
  const port = Number(options.port || process.argv[2] || 8888);
  const server = createServer({ ...options, port });
  server.listen(port, '127.0.0.1', () => {
    log('info', 'server.started', { url: `http://localhost:${port}` });
  });
  return server;
}

if (require.main === module) {
  startServer();
}

module.exports = {
  createServer,
  startServer,
  testGateway
};
