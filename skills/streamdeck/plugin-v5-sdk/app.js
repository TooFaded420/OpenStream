/* OpenClaw Stream Deck SDK v5 runtime with Dial Pack v1 + Gateway Switcher v1 */
// Node 22+ (global fetch + WebSocket)
// Dial Pack: 4 encoder actions - Model, TTS, Agents, Profile
// Gateway Switcher: Config-driven gateway management with health monitoring

const fs = require('fs');
const path = require('path');
const { spawn } = require('child_process');

const args = process.argv.slice(2);
const getArg = (name) => {
  const i = args.indexOf(name);
  return i >= 0 ? args[i + 1] : undefined;
};

const PORT = getArg('-port');
const PLUGIN_UUID = getArg('-pluginUUID');
const REGISTER_EVENT = getArg('-registerEvent');

if (!PORT || !PLUGIN_UUID || !REGISTER_EVENT) {
  console.error('[openclaw-v5] Missing SDK launch args', { PORT, PLUGIN_UUID, REGISTER_EVENT });
  process.exit(1);
}

const ws = new WebSocket(`ws://127.0.0.1:${PORT}`);

// Config paths
const CONFIG_DIR = path.join(process.env.USERPROFILE || process.env.HOME, '.openclaw');
const GATEWAY_CONFIG_PATH = path.join(CONFIG_DIR, 'streamdeck-gateways.json');

// Default gateway configuration
const DEFAULT_GATEWAY = {
  url: 'http://127.0.0.1:18790',
  token: null
};

// Load or initialize gateway config
function loadGatewayConfig() {
  try {
    if (fs.existsSync(GATEWAY_CONFIG_PATH)) {
      const data = JSON.parse(fs.readFileSync(GATEWAY_CONFIG_PATH, 'utf-8'));
      console.log('[openclaw-v5] Loaded gateway config from', GATEWAY_CONFIG_PATH);
      return {
        active: data.active || 'default',
        gateways: data.gateways || { default: { ...DEFAULT_GATEWAY } }
      };
    }
  } catch (e) {
    console.error('[openclaw-v5] Failed to load gateway config:', e.message);
  }
  
  // Return default config if no file exists
  return {
    active: 'default',
    gateways: {
      default: { ...DEFAULT_GATEWAY }
    }
  };
}

// Save gateway config
function saveGatewayConfig(config) {
  try {
    if (!fs.existsSync(CONFIG_DIR)) {
      fs.mkdirSync(CONFIG_DIR, { recursive: true });
    }
    fs.writeFileSync(GATEWAY_CONFIG_PATH, JSON.stringify(config, null, 2), 'utf-8');
    console.log('[openclaw-v5] Saved gateway config to', GATEWAY_CONFIG_PATH);
    return true;
  } catch (e) {
    console.error('[openclaw-v5] Failed to save gateway config:', e.message);
    return false;
  }
}

// Gateway configuration state
let gatewayConfig = loadGatewayConfig();

// Get current gateway URL and token
function getCurrentGateway() {
  const key = gatewayConfig.active;
  const gw = gatewayConfig.gateways[key];
  if (gw) {
    return { key, url: gw.url, token: gw.token };
  }
  // Fallback to default
  return { key: 'default', ...DEFAULT_GATEWAY };
}

// Set active gateway
function setActiveGateway(key) {
  if (gatewayConfig.gateways[key]) {
    gatewayConfig.active = key;
    saveGatewayConfig(gatewayConfig);
    return true;
  }
  return false;
}

// Get all gateway keys as array
function getGatewayKeys() {
  return Object.keys(gatewayConfig.gateways);
}

// Get active gateway index
function getActiveGatewayIndex() {
  const keys = getGatewayKeys();
  return keys.indexOf(gatewayConfig.active);
}

// Cycle to next gateway
function cycleGateway() {
  const keys = getGatewayKeys();
  const currentIdx = keys.indexOf(gatewayConfig.active);
  const nextIdx = (currentIdx + 1) % keys.length;
  const nextKey = keys[nextIdx];
  setActiveGateway(nextKey);
  return { key: nextKey, ...gatewayConfig.gateways[nextKey] };
}

// Runtime configuration
const cfg = {
  timeoutMs: 9000,
  defaultSearch: 'latest openclaw updates'
};

const defaultTitles = {
  'com.openclaw.v5.status': 'Status',
  'com.openclaw.v5.tts': 'TTS',
  'com.openclaw.v5.spawn': 'Spawn',
  'com.openclaw.v5.session': 'Session',
  'com.openclaw.v5.subagents': 'Agents',
  'com.openclaw.v5.nodes': 'Nodes',
  'com.openclaw.v5.websearch': 'Search',
  'com.openclaw.v5.reconnect': 'Ping',
  'com.openclaw.v5.gateway.next': 'Gateway',
  'com.openclaw.v5.setup.wizard': 'Wizard',
  'com.openclaw.v5.dial.model': 'Model',
  'com.openclaw.v5.dial.tts': 'TTS',
  'com.openclaw.v5.dial.agents': 'Agents',
  'com.openclaw.v5.dial.profile': 'Gateway'
};

// Dial state management
const dialState = {
  models: ['synthetic/hf:nvidia/Kimi-K2.5-NVFP4', 'synthetic/vertex/gemini-2.5-pro', 'anthropic/claude-3.5-sonnet', 'openai/gpt-4o'],
  modelIndex: 0,
  ttsVolume: 100,
  ttsMuted: false,
  agents: [],
  agentIndex: 0,
  // Gateway health cache: { key: { ok: boolean, latencyMs: number, checkedAt: number } }
  gatewayHealth: {}
};

// Gateway health check cache duration (ms)
const HEALTH_CACHE_MS = 30000;

function send(obj) {
  if (ws.readyState === WebSocket.OPEN) ws.send(JSON.stringify(obj));
}

function setTitle(context, title) {
  send({ event: 'setTitle', context, payload: { title, target: 0 } });
}

function showBusy(context, title = '...') { setTitle(context, title); }
function showOk(context, title = 'OK') { setTitle(context, title); }
function showErr(context, title = 'ERR') { setTitle(context, title); }

function errCode(res) {
  if (!res) return 'ERR';
  if (res.status === 401 || res.status === 403) return 'AUTH';
  if (res.status === 404) return 'NF';
  if (res.status === 0) {
    const msg = String(res.data?.error || '').toLowerCase();
    if (msg.includes('abort') || msg.includes('timeout')) return 'TIME';
    return 'OFF';
  }
  return 'ERR';
}

async function callGateway(path, method = 'GET', body, gatewayOverride = null) {
  const gw = gatewayOverride || getCurrentGateway();
  console.log('[openclaw-v5] api', method, path, 'via', gw.key);
  const ac = new AbortController();
  const t = setTimeout(() => ac.abort(), cfg.timeoutMs);
  
  try {
    const headers = { 'content-type': 'application/json' };
    if (gw.token) {
      headers['authorization'] = `Bearer ${gw.token}`;
    }
    
    const r = await fetch(`${gw.url}${path}`, {
      method,
      headers,
      body: body ? JSON.stringify(body) : undefined,
      signal: ac.signal
    });
    const text = await r.text();
    let data;
    try { data = text ? JSON.parse(text) : {}; } catch { data = { raw: text }; }
    return { ok: r.ok, status: r.status, data, gateway: gw.key };
  } catch (e) {
    return { ok: false, status: 0, data: { error: String(e) }, gateway: gw.key };
  } finally {
    clearTimeout(t);
  }
}

// Check gateway health
async function checkGatewayHealth(key) {
  const now = Date.now();
  const cached = dialState.gatewayHealth[key];
  
  // Return cached if recent
  if (cached && (now - cached.checkedAt) < HEALTH_CACHE_MS) {
    return cached;
  }
  
  const gw = gatewayConfig.gateways[key];
  if (!gw) return { ok: false, latencyMs: 0, checkedAt: now, key };
  
  const start = Date.now();
  try {
    const ac = new AbortController();
    const t = setTimeout(() => ac.abort(), cfg.timeoutMs);
    const r = await fetch(`${gw.url}/status`, {
      method: 'GET',
      headers: gw.token ? { 'authorization': `Bearer ${gw.token}` } : {},
      signal: ac.signal
    });
    clearTimeout(t);
    
    const latencyMs = Date.now() - start;
    const result = { 
      ok: r.ok, 
      latencyMs, 
      checkedAt: now, 
      key,
      code: r.ok ? 'OK' : errCode({ ok: r.ok, status: r.status })
    };
    dialState.gatewayHealth[key] = result;
    return result;
  } catch (e) {
    const result = { 
      ok: false, 
      latencyMs: 0, 
      checkedAt: now, 
      key,
      code: 'OFF'
    };
    dialState.gatewayHealth[key] = result;
    return result;
  }
}

// Check all gateways health
async function checkAllGatewaysHealth() {
  const keys = getGatewayKeys();
  const results = await Promise.all(keys.map(k => checkGatewayHealth(k)));
  return results;
}

function backToDefault(context, action) {
  setTimeout(() => setTitle(context, defaultTitles[action] || 'Ready'), 1800);
}

function launchSetupWizard() {
  try {
    const workspace = path.join(process.env.USERPROFILE || process.env.HOME, '.openclaw', 'workspace', 'skills', 'streamdeck', 'web-dashboard');
    const startBat = path.join(workspace, 'START-SERVER.bat');
    // Start local dashboard/wizard server on 8787 (best-effort)
    spawn('cmd.exe', ['/c', 'start', '""', startBat, '8787'], { detached: true, stdio: 'ignore' }).unref();
    // Open wizard in browser
    spawn('cmd.exe', ['/c', 'start', '""', 'http://localhost:8787/wizard'], { detached: true, stdio: 'ignore' }).unref();
    return true;
  } catch (e) {
    console.error('[openclaw-v5] launchSetupWizard failed:', e.message);
    return false;
  }
}

async function handleKeyUp(evt) {
  const { context, action } = evt;
  console.log('[openclaw-v5] keyUp action=', action);
  showBusy(context);

  if (action === 'com.openclaw.v5.status' || action === 'com.openclaw.v5.reconnect') {
    const res = await callGateway('/status');
    if (res.ok) {
      const latency = String(res.data?.latencyMs ?? 'OK');
      showOk(context, latency.slice(0, 4));
    } else showErr(context, errCode(res));
    return backToDefault(context, action);
  }

  if (action === 'com.openclaw.v5.tts') {
    const getRes = await callGateway('/config.get');
    const enabled = !!(getRes.data?.messages?.tts?.enabled);
    const setRes = await callGateway('/config.patch', 'POST', {
      path: 'messages.tts.enabled',
      value: !enabled
    });
    if (setRes.ok) showOk(context, !enabled ? 'ON' : 'OFF');
    else showErr(context, errCode(setRes));
    return backToDefault(context, action);
  }

  if (action === 'com.openclaw.v5.spawn') {
    const res = await callGateway('/spawn', 'POST', {
      task: 'Quick assistance',
      agentId: 'helper'
    });
    if (res.ok) showOk(context, 'SPWN');
    else showErr(context, errCode(res));
    return backToDefault(context, action);
  }

  if (action === 'com.openclaw.v5.session') {
    const res = await callGateway('/session.status');
    if (res.ok) {
      const model = String(res.data?.model || 'OK').split('/').pop();
      showOk(context, model.slice(0, 4));
    } else showErr(context, errCode(res));
    return backToDefault(context, action);
  }

  if (action === 'com.openclaw.v5.subagents') {
    const res = await callGateway('/subagents.list');
    if (res.ok) {
      const count = Array.isArray(res.data?.agents) ? res.data.agents.length : 0;
      showOk(context, `${count}`);
    } else showErr(context, errCode(res));
    return backToDefault(context, action);
  }

  if (action === 'com.openclaw.v5.nodes') {
    const res = await callGateway('/nodes.status');
    if (res.ok) {
      const count = Array.isArray(res.data?.nodes) ? res.data.nodes.length : 0;
      showOk(context, `${count}`);
    } else showErr(context, errCode(res));
    return backToDefault(context, action);
  }

  if (action === 'com.openclaw.v5.websearch') {
    const res = await callGateway('/web.search', 'POST', { query: cfg.defaultSearch, count: 1 });
    if (res.ok) showOk(context, 'FND');
    else showErr(context, errCode(res));
    return backToDefault(context, action);
  }

  if (action === 'com.openclaw.v5.setup.wizard') {
    const ok = launchSetupWizard();
    if (ok) showOk(context, 'OPEN');
    else showErr(context, 'ERR');
    return backToDefault(context, action);
  }

  // Gateway Switcher v1: Next Gateway key action
  if (action === 'com.openclaw.v5.gateway.next') {
    const keys = getGatewayKeys();
    if (keys.length <= 1) {
      showOk(context, '1 GW');
      return backToDefault(context, action);
    }
    
    const prevKey = gatewayConfig.active;
    const next = cycleGateway();
    const health = await checkGatewayHealth(next.key);
    
    const shortKey = next.key.slice(0, 4).toUpperCase();
    if (health.ok) {
      showOk(context, shortKey);
    } else {
      showErr(context, health.code || 'OFF');
    }
    
    // Update dashboard if available
    updateDashboardGatewayInfo();
    return backToDefault(context, action);
  }

  showErr(context, '?');
  return backToDefault(context, action);
}

function setFeedback(context, payload) {
  send({ event: 'setFeedback', context, payload });
}

// Dial 1: Model cycle/apply
async function handleModelDial(evt) {
  const { context, payload } = evt;
  const { ticks } = payload || {};
  const len = dialState.models.length;
  if (ticks) {
    dialState.modelIndex = ((dialState.modelIndex + ticks) % len + len) % len;
    const short = dialState.models[dialState.modelIndex].split('/').pop().slice(0, 8);
    setFeedback(context, { title: 'Model', value: short });
  }
}

async function handleModelDialPress(evt) {
  const { context } = evt;
  const model = dialState.models[dialState.modelIndex];
  setFeedback(context, { title: '...', value: 'Apply' });
  const res = await callGateway('/session.set', 'POST', { model });
  const short = model.split('/').pop().slice(0, 6);
  setFeedback(context, { title: res.ok ? 'OK' : errCode(res), value: short });
}

// Dial 2: TTS control + mute press
async function handleTtsDial(evt) {
  const { context, payload } = evt;
  const { ticks } = payload || {};
  if (ticks) {
    dialState.ttsVolume = Math.max(0, Math.min(100, dialState.ttsVolume + ticks * 5));
  }
  const vol = dialState.ttsMuted ? 'MUTED' : `${dialState.ttsVolume}%`;
  setFeedback(context, { title: 'TTS Vol', value: vol });
}

async function handleTtsDialPress(evt) {
  const { context } = evt;
  dialState.ttsMuted = !dialState.ttsMuted;
  const vol = dialState.ttsMuted ? 'MUTED' : `${dialState.ttsVolume}%`;
  setFeedback(context, { title: dialState.ttsMuted ? 'OFF' : 'ON', value: vol });
}

// Dial 3: Session/subagent navigator
async function handleAgentsDial(evt) {
  const { context, payload } = evt;
  const { ticks } = payload || {};
  const res = await callGateway('/subagents.list');
  dialState.agents = Array.isArray(res.data?.agents) ? res.data.agents : [];
  const len = Math.max(1, dialState.agents.length);
  if (ticks) {
    dialState.agentIndex = ((dialState.agentIndex + ticks) % len + len) % len;
  }
  const agent = dialState.agents[dialState.agentIndex];
  const name = agent?.name?.slice(0, 8) || `(${dialState.agentIndex + 1}/${len})`;
  setFeedback(context, { title: 'Agent', value: name });
}

async function handleAgentsDialPress(evt) {
  const { context } = evt;
  const agent = dialState.agents[dialState.agentIndex];
  if (!agent?.id) {
    setFeedback(context, { title: 'Agent', value: 'None' });
    return;
  }
  setFeedback(context, { title: '...', value: 'Kill' });
  const res = await callGateway('/subagents.kill', 'POST', { target: agent.id });
  setFeedback(context, { title: res.ok ? 'OK' : errCode(res), value: agent.name?.slice(0, 6) || '?' });
}

// Dial 4: Gateway profile switch + ping press (Gateway Switcher v1)
async function handleProfileDial(evt) {
  const { context, payload } = evt;
  const { ticks } = payload || {};
  const keys = getGatewayKeys();
  const len = keys.length;
  
  if (ticks) {
    const currentIdx = keys.indexOf(gatewayConfig.active);
    const nextIdx = ((currentIdx + ticks) % len + len) % len;
    const nextKey = keys[nextIdx];
    // Preview the gateway but don't apply yet
    setFeedback(context, { title: nextKey, value: 'Select' });
  } else {
    // Show current gateway on initial appear
    const health = dialState.gatewayHealth[gatewayConfig.active];
    const status = health ? (health.ok ? `${health.latencyMs}ms` : health.code) : '...';
    setFeedback(context, { title: gatewayConfig.active, value: status });
  }
}

async function handleProfileDialPress(evt) {
  const { context } = evt;
  const keys = getGatewayKeys();
  const currentIdx = keys.indexOf(gatewayConfig.active);
  const nextIdx = (currentIdx + 1) % keys.length;
  const nextKey = keys[nextIdx];
  
  setFeedback(context, { title: '...', value: 'Apply' });
  
  // Apply the gateway
  if (setActiveGateway(nextKey)) {
    // Ping to verify
    const health = await checkGatewayHealth(nextKey);
    const latency = health.ok ? `${health.latencyMs}ms` : health.code;
    setFeedback(context, { title: nextKey, value: latency });
  } else {
    setFeedback(context, { title: 'ERR', value: nextKey });
  }
}

// Track dashboard context for updates
let dashboardContext = null;
let dashboardAction = null;

// Update dashboard with gateway info
async function updateDashboardGatewayInfo() {
  if (!dashboardContext) return;
  
  const health = await checkGatewayHealth(gatewayConfig.active);
  const status = health.ok ? '●' : '○';
  const title = `${status} ${gatewayConfig.active}`;
  setTitle(dashboardContext, title.slice(0, 6));
}

ws.addEventListener('open', () => {
  send({ event: REGISTER_EVENT, uuid: PLUGIN_UUID });
  console.log('[openclaw-v5] registered');
  console.log('[openclaw-v5] Active gateway:', gatewayConfig.active);
  console.log('[openclaw-v5] Available gateways:', Object.keys(gatewayConfig.gateways).join(', '));
});

ws.addEventListener('message', async (event) => {
  let evt;
  try { evt = JSON.parse(String(event.data)); } catch { return; }
  try { console.log('[openclaw-v5] evt', evt.event, evt.action || '', evt.context || ''); } catch {}

  if (evt.event === 'willAppear') {
    const title = defaultTitles[evt.action] || 'Ready';
    setTitle(evt.context, title);
    
    // Track dashboard actions (Status key can serve as dashboard)
    if (evt.action === 'com.openclaw.v5.status') {
      dashboardContext = evt.context;
      dashboardAction = evt.action;
      // Update with current gateway info
      updateDashboardGatewayInfo();
    }
    return;
  }

  if (evt.event === 'willDisappear') {
    if (evt.context === dashboardContext) {
      dashboardContext = null;
      dashboardAction = null;
    }
    return;
  }

  if (evt.event === 'keyUp') {
    await handleKeyUp(evt);
    return;
  }

  if (evt.event === 'dialRotate') {
    const action = evt.action;
    if (action === 'com.openclaw.v5.dial.model') await handleModelDial(evt);
    else if (action === 'com.openclaw.v5.dial.tts') await handleTtsDial(evt);
    else if (action === 'com.openclaw.v5.dial.agents') await handleAgentsDial(evt);
    else if (action === 'com.openclaw.v5.dial.profile') await handleProfileDial(evt);
    return;
  }

  if (evt.event === 'dialUp') {
    const action = evt.action;
    if (action === 'com.openclaw.v5.dial.model') await handleModelDialPress(evt);
    else if (action === 'com.openclaw.v5.dial.tts') await handleTtsDialPress(evt);
    else if (action === 'com.openclaw.v5.dial.agents') await handleAgentsDialPress(evt);
    else if (action === 'com.openclaw.v5.dial.profile') await handleProfileDialPress(evt);
    return;
  }

  if (evt.event === 'didReceiveSettings') {
    const s = evt.payload?.settings || {};
    // Support for per-action gateway override in settings
    if (s.gatewayUrl) {
      const current = getCurrentGateway();
      // Update current gateway URL if provided via settings
      if (gatewayConfig.gateways[current.key]) {
        gatewayConfig.gateways[current.key].url = String(s.gatewayUrl);
        saveGatewayConfig(gatewayConfig);
      }
    }
    if (s.gatewayToken && gatewayConfig.gateways[gatewayConfig.active]) {
      gatewayConfig.gateways[gatewayConfig.active].token = String(s.gatewayToken);
      saveGatewayConfig(gatewayConfig);
    }
    if (s.timeoutMs) cfg.timeoutMs = Number(s.timeoutMs) || cfg.timeoutMs;
    if (s.defaultSearch) cfg.defaultSearch = String(s.defaultSearch);
  }
});

ws.addEventListener('close', () => process.exit(0));
ws.addEventListener('error', (e) => {
  console.error('[openclaw-v5] ws error', e?.message || e);
  process.exit(1);
});
