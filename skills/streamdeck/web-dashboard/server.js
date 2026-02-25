const http = require('http');
const fs = require('fs');
const path = require('path');

const port = Number(process.argv[2] || 8787);
const root = __dirname;
const gatewayCfgPath = path.join(process.env.USERPROFILE || process.env.HOME, '.openclaw', 'streamdeck-gateways.json');
const deviceMapPath = path.join(process.env.USERPROFILE || process.env.HOME, '.openclaw', 'streamdeck-device-map.json');

function readText(p){ return fs.existsSync(p) ? fs.readFileSync(p,'utf8') : ''; }
function json(res, obj){ const s = JSON.stringify(obj, null, 2); res.writeHead(200, {'content-type':'application/json; charset=utf-8'}); res.end(s); }
function text(res, s, code=200, type='text/plain'){ res.writeHead(code, {'content-type': `${type}; charset=utf-8`}); res.end(s); }
function loadCfg(){
  try { return JSON.parse(readText(gatewayCfgPath)); } catch {}
  return { active:'origin-main', gateways:{ 'origin-main': { url:'http://127.0.0.1:18790', token:null } } };
}
function saveCfg(cfg){ fs.mkdirSync(path.dirname(gatewayCfgPath), {recursive:true}); fs.writeFileSync(gatewayCfgPath, JSON.stringify(cfg,null,2)); }

async function testGateway(url, token){
  const started = Date.now();
  try {
    const headers = token ? { Authorization: `Bearer ${token}` } : {};
    const r = await fetch(`${url}/status`, { headers, signal: AbortSignal.timeout(3000) });
    if (!r.ok) {
      const code = (r.status===401||r.status===403)?'AUTH':'ERR';
      return { ok:false, code, latencyMs: null };
    }
    return { ok:true, code:'OK', latencyMs: Date.now()-started };
  } catch (e) {
    const m = String(e.message||'').toLowerCase();
    const code = m.includes('timeout') || m.includes('aborted') ? 'TIME' : 'OFF';
    return { ok:false, code, latencyMs: null };
  }
}

const server = http.createServer(async (req,res)=>{
  const url = new URL(req.url, `http://localhost:${port}`);
  const p = url.pathname;

  if (p === '/' || p === '/index.html') return text(res, readText(path.join(root,'index.html')), 200, 'text/html');
  if (p === '/wizard' || p === '/wizard.html') return text(res, readText(path.join(root,'wizard.html')), 200, 'text/html');
  if (p === '/api/device-map') {
    try { return json(res, JSON.parse(readText(deviceMapPath)||'{}')); } catch { return json(res, {}); }
  }

  if (p === '/api/gateway-config' && req.method === 'GET') return json(res, loadCfg());
  if (p === '/api/gateway-config' && req.method === 'POST') {
    let body=''; req.on('data',d=>body+=d); req.on('end',()=>{
      try { const cfg = JSON.parse(body||'{}'); saveCfg(cfg); json(res, loadCfg()); }
      catch(e){ text(res, `Bad JSON: ${e.message}`, 400); }
    });
    return;
  }

  if (p === '/api/detect-local' && req.method === 'POST') {
    let body=''; req.on('data',d=>body+=d); req.on('end', async ()=>{
      const cfg = loadCfg();
      let host='127.0.0.1';
      let ports=['18790','18789','28790'];
      try {
        const b = JSON.parse(body||'{}');
        if (typeof b.host === 'string' && b.host.trim()) host = b.host.trim();
        if (Array.isArray(b.ports)) ports = b.ports.map(String);
      } catch {}
      const gateways = { ...(cfg.gateways||{}) };
      for (const pt of ports){
        const name = pt==='18790' ? 'origin-main' : (pt==='18789' ? 'zero-mac' : `local-${pt}`);
        const url = `http://${host}:${pt}`;
        const t = await testGateway(url, gateways[name]?.token || null);
        if (t.ok) gateways[name] = { url, token: gateways[name]?.token || null };
      }
      const out = { active: cfg.active, gateways };
      if (!out.gateways[out.active]) out.active = Object.keys(out.gateways)[0] || 'origin-main';
      saveCfg(out);
      json(res, out);
    });
    return;
  }

  if (p === '/api/test-gateways') {
    const cfg = loadCfg();
    const out = {};
    for (const [k,g] of Object.entries(cfg.gateways||{})) out[k] = await testGateway(g.url, g.token);
    return json(res, out);
  }

  if (p === '/api/apply-best-gateway' && req.method === 'POST') {
    const cfg = loadCfg();
    let best = null;
    for (const [k,g] of Object.entries(cfg.gateways||{})) {
      const t = await testGateway(g.url, g.token);
      if (t.ok && (!best || t.latencyMs < best.latencyMs)) best = { key:k, latencyMs:t.latencyMs };
    }
    if (!best) return json(res, { ok:false, error:'No healthy gateways found' });
    cfg.active = best.key; saveCfg(cfg); return json(res, { ok:true, active:best.key, latencyMs:best.latencyMs });
  }

  text(res, 'Not Found', 404);
});

server.listen(port, '127.0.0.1', ()=>{
  console.log(`OpenClaw Dashboard server running on http://localhost:${port}`);
});
