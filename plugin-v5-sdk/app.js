/* OpenClaw Stream Deck SDK v5 runtime with Dial Pack v1 + Gateway Switcher v1 + Lobster Animator v1 */
// Node 22+ (global fetch + WebSocket)
// Dial Pack: 4 encoder actions - Model, TTS, Agents, Profile
// Gateway Switcher: Config-driven gateway management with health monitoring
// Lobster Animator: Touch-strip feedback animations for dial actions

const fs = require('fs');
const path = require('path');
const { spawn } = require('child_process');
const { invokeGatewayCall } = require('./lib/gateway-call');
const { chooseGatewayKey, normalizeContextRoutingSettings, normalizeRouteMode } = require('./lib/routing');

// Config paths
const CONFIG_DIR = path.join(process.env.USERPROFILE || process.env.HOME, '.openclaw');
const GATEWAY_CONFIG_PATH = path.join(CONFIG_DIR, 'streamdeck-gateways.json');
const TELEMETRY_PATH = path.join(CONFIG_DIR, 'telemetry.json');
const TELEMETRY_EXPORT_PATH = path.join(CONFIG_DIR, 'telemetry-export.json');
const OPENCLAW_CONFIG_PATH = path.join(CONFIG_DIR, 'openclaw.json');
const LOCAL_SETUP_WIZARD_PATH = path.join(__dirname, 'setup-wizard.html');

// Default gateway configuration
const DEFAULT_GATEWAY = {
  url: 'http://127.0.0.1:18790',
  token: null
};

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

function ensureConfigDir() {
  if (!fs.existsSync(CONFIG_DIR)) {
    fs.mkdirSync(CONFIG_DIR, { recursive: true });
  }
}

function readJsonFileSafe(filePath) {
  const raw = fs.readFileSync(filePath, 'utf-8').replace(/^\uFEFF/, '');
  return JSON.parse(raw);
}

function normalizeGatewayEntry(raw) {
  const inputUrl = typeof raw?.url === 'string' ? raw.url.trim() : '';
  if (!inputUrl) return null;
  try {
    const parsed = new URL(inputUrl);
    if (parsed.protocol !== 'http:' && parsed.protocol !== 'https:') {
      return null;
    }
    const token = typeof raw?.token === 'string' && raw.token.trim() ? raw.token.trim() : null;
    return { url: parsed.toString().replace(/\/$/, ''), token };
  } catch {
    return null;
  }
}

function normalizeGatewayConfig(input) {
  const gateways = {};
  const rawGateways = input && typeof input.gateways === 'object' ? input.gateways : {};
  for (const [key, raw] of Object.entries(rawGateways || {})) {
    if (!key || typeof key !== 'string') continue;
    const normalized = normalizeGatewayEntry(raw);
    if (normalized) gateways[key] = normalized;
  }
  if (Object.keys(gateways).length === 0) {
    gateways.default = { ...DEFAULT_GATEWAY };
  }
  const active = typeof input?.active === 'string' && gateways[input.active] ? input.active : Object.keys(gateways)[0];
  const routeRoles = {
    default: typeof input?.routeRoles?.default === 'string' && gateways[input.routeRoles.default] ? input.routeRoles.default : active,
    audio: typeof input?.routeRoles?.audio === 'string' && gateways[input.routeRoles.audio] ? input.routeRoles.audio : active,
    research: typeof input?.routeRoles?.research === 'string' && gateways[input.routeRoles.research] ? input.routeRoles.research : active,
    agents: typeof input?.routeRoles?.agents === 'string' && gateways[input.routeRoles.agents] ? input.routeRoles.agents : active,
    session: typeof input?.routeRoles?.session === 'string' && gateways[input.routeRoles.session] ? input.routeRoles.session : active,
    nodes: typeof input?.routeRoles?.nodes === 'string' && gateways[input.routeRoles.nodes] ? input.routeRoles.nodes : active
  };
  return { active, gateways, routeRoles };
}

// ============ LOBSTER ANIMATOR v1 ============
// Feature flag - set to false to disable animations
const LOBSTER_ANIM_ENABLED = true;

const LOBSTER_ANIM_PATH = path.join(__dirname, 'lobster-anim-v1.json');
let lobsterAnimData = null;
let lobsterAnims = new Map(); // context -> animation state

// Load animation frames
function loadLobsterAnims() {
  if (!LOBSTER_ANIM_ENABLED) return;
  try {
    if (fs.existsSync(LOBSTER_ANIM_PATH)) {
      const raw = fs.readFileSync(LOBSTER_ANIM_PATH, 'utf-8');
      lobsterAnimData = JSON.parse(raw);
      log('info', 'lobster_anim.loaded', { states: Object.keys(lobsterAnimData.states) });
    } else {
      log('warn', 'lobster_anim.missing');
    }
  } catch (e) {
    log('error', 'lobster_anim.load_failed', { error: e.message });
    lobsterAnimData = null;
  }
}

// Animation instance for a dial context
class LobsterAnimation {
  constructor(context, stateName = 'idle') {
    this.context = context;
    this.stateName = stateName;
    this.frameIndex = 0;
    this.isPlaying = false;
    this.timer = null;
    this.stateConfig = null;
    this.frames = [];
    this.setState(stateName);
  }

  setState(stateName) {
    if (!lobsterAnimData || !lobsterAnimData.states[stateName]) {
      this.stateConfig = null;
      this.frames = [];
      return false;
    }
    this.stateName = stateName;
    this.stateConfig = lobsterAnimData.states[stateName];
    this.frames = this.stateConfig.frames || [];
    this.frameIndex = 0;
    return true;
  }

  getCurrentFrame() {
    if (!this.frames.length) return null;
    return this.frames[this.frameIndex % this.frames.length];
  }

  advance() {
    if (!this.frames.length) return null;
    const frame = this.frames[this.frameIndex];
    this.frameIndex++;
    
    // Handle loop vs one-shot
    if (this.frameIndex >= this.frames.length) {
      if (this.stateConfig.loop) {
        this.frameIndex = 0;
      } else {
        this.frameIndex = this.frames.length - 1;
        this.stop();
        // Auto-return to idle after non-loop animations
        const returnMs = lobsterAnimData.config?.returnToIdleAfterMs || 2000;
        setTimeout(() => {
          if (!this.isPlaying) {
            this.setState('idle');
            this.start();
          }
        }, returnMs);
      }
    }
    return frame;
  }

  start() {
    if (!LOBSTER_ANIM_ENABLED || !this.frames.length || this.isPlaying) return;
    this.isPlaying = true;
    this.tick();
  }

  stop() {
    this.isPlaying = false;
    if (this.timer) {
      clearTimeout(this.timer);
      this.timer = null;
    }
  }

  tick() {
    if (!this.isPlaying) return;
    
    const frame = this.advance();
    if (frame) {
      // Update touch strip feedback with animation frame
      setFeedbackRaw(this.context, { icon: frame });
    }
    
    // Schedule next frame
    if (this.isPlaying && this.stateConfig) {
      const fps = this.stateConfig.fps || 8;
      const intervalMs = Math.max(1000 / fps, 16); // Min 16ms (~60fps max)
      this.timer = setTimeout(() => this.tick(), intervalMs);
    }
  }

  destroy() {
    this.stop();
    lobsterAnims.delete(this.context);
  }
}

// Get or create animation for a context
function getAnim(context, stateName = null) {
  if (!LOBSTER_ANIM_ENABLED) return null;
  let anim = lobsterAnims.get(context);
  if (!anim) {
    anim = new LobsterAnimation(context, stateName || 'idle');
    lobsterAnims.set(context, anim);
  } else if (stateName) {
    anim.setState(stateName);
  }
  return anim;
}

// Set animation state for a context
function setAnimState(context, stateName) {
  const anim = getAnim(context, stateName);
  if (anim) {
    anim.stop();
    anim.setState(stateName);
    anim.start();
  }
}

// Stop animation for a context
function stopAnim(context) {
  const anim = lobsterAnims.get(context);
  if (anim) anim.stop();
}

// Clean up animation when dial disappears
function destroyAnim(context) {
  const anim = lobsterAnims.get(context);
  if (anim) anim.destroy();
}

// Initialize animations
loadLobsterAnims();

// ============ TELEMETRY v1.1 ============
const TELEMETRY_MAX_EVENTS = 100;
const TELEMETRY_FLUSH_INTERVAL_MS = 5000;
const TELEMETRY_EXPORT_INTERVAL_MS = 10000;

let telemetryEvents = [];
let telemetryFlushTimer = null;
let telemetryExportTimer = null;

// Load persisted telemetry
function loadTelemetry() {
  try {
    if (fs.existsSync(TELEMETRY_PATH)) {
      const data = readJsonFileSafe(TELEMETRY_PATH);
      if (Array.isArray(data.events)) {
        telemetryEvents = data.events.slice(-TELEMETRY_MAX_EVENTS);
        log('info', 'telemetry.loaded', { count: telemetryEvents.length });
      }
    }
  } catch (e) {
    log('error', 'telemetry.load_failed', { error: e.message });
    telemetryEvents = [];
  }
}

// Save telemetry to disk (throttled)
function flushTelemetry() {
  try {
    ensureConfigDir();
    const data = {
      version: '1.1',
      updatedAt: Date.now(),
      events: telemetryEvents.slice(-TELEMETRY_MAX_EVENTS)
    };
    fs.writeFileSync(TELEMETRY_PATH, JSON.stringify(data, null, 2), 'utf-8');
  } catch (e) {
    log('error', 'telemetry.flush_failed', { error: e.message });
  }
}

// Schedule a flush
function scheduleFlush() {
  if (telemetryFlushTimer) clearTimeout(telemetryFlushTimer);
  telemetryFlushTimer = setTimeout(flushTelemetry, TELEMETRY_FLUSH_INTERVAL_MS);
}

function scheduleTelemetryExport() {
  if (telemetryExportTimer) return;
  telemetryExportTimer = setTimeout(() => {
    telemetryExportTimer = null;
    exportTelemetryForDashboard();
  }, 150);
}

// Record a telemetry event
function recordTelemetry(action, result, latencyMs, statusCode, details = {}) {
  const event = {
    id: `${Date.now()}-${Math.random().toString(36).slice(2, 7)}`,
    timestamp: Date.now(),
    action,
    result, // 'ok' | 'err'
    latencyMs,
    statusCode, // 'OK' | 'AUTH' | 'TIME' | 'OFF' | 'ERR' | 'NF'
    gateway: details.gateway || getCurrentGateway().key,
    model: details.model || null,
    ...details
  };
  telemetryEvents.push(event);
  if (telemetryEvents.length > TELEMETRY_MAX_EVENTS) {
    telemetryEvents = telemetryEvents.slice(-TELEMETRY_MAX_EVENTS);
  }
  scheduleFlush();
  scheduleTelemetryExport();
  return event;
}

// Get telemetry summary for dashboard
function getTelemetrySummary() {
  const now = Date.now();
  const windowMs = 5 * 60 * 1000; // 5 minute window
  const recent = telemetryEvents.filter(e => now - e.timestamp < windowMs);
  
  const total = recent.length;
  const ok = recent.filter(e => e.result === 'ok').length;
  const errors = total - ok;
  
  const latencies = recent.filter(e => e.latencyMs > 0).map(e => e.latencyMs);
  const avgLatency = latencies.length > 0 
    ? Math.round(latencies.reduce((a, b) => a + b, 0) / latencies.length) 
    : 0;
  const maxLatency = latencies.length > 0 ? Math.max(...latencies) : 0;
  const minLatency = latencies.length > 0 ? Math.min(...latencies) : 0;
  
  // Status code breakdown
  const codes = {};
  recent.forEach(e => { codes[e.statusCode] = (codes[e.statusCode] || 0) + 1; });
  
  // Recent errors (last 5)
  const recentErrors = recent
    .filter(e => e.result === 'err')
    .slice(-5)
    .map(e => ({ action: e.action, code: e.statusCode, at: e.timestamp }));
  
  return {
    window: '5m',
    total,
    successRate: total > 0 ? Math.round((ok / total) * 100) : 100,
    avgLatency,
    minLatency,
    maxLatency,
    codes,
    recentErrors,
    lastEvent: telemetryEvents.length > 0 ? telemetryEvents[telemetryEvents.length - 1].timestamp : null
  };
}

// Get recent telemetry events
function getRecentTelemetry(count = 20) {
  return telemetryEvents.slice(-count).reverse();
}

// Clear telemetry
function clearTelemetry() {
  telemetryEvents = [];
  flushTelemetry();
}

// Initialize telemetry
loadTelemetry();

const args = process.argv.slice(2);
const getArg = (name) => {
  const i = args.indexOf(name);
  return i >= 0 ? args[i + 1] : undefined;
};

const PORT = getArg('-port');
const PLUGIN_UUID = getArg('-pluginUUID');
const REGISTER_EVENT = getArg('-registerEvent');

if (!PORT || !PLUGIN_UUID || !REGISTER_EVENT) {
  log('error', 'sdk.launch_args_missing', { PORT, PLUGIN_UUID, REGISTER_EVENT });
  process.exit(1);
}

const ws = new WebSocket(`ws://127.0.0.1:${PORT}`);

// Load or initialize gateway config
function loadGatewayConfig() {
  try {
    if (fs.existsSync(GATEWAY_CONFIG_PATH)) {
      const data = readJsonFileSafe(GATEWAY_CONFIG_PATH);
      log('info', 'gateway_config.loaded', { path: GATEWAY_CONFIG_PATH });
      return normalizeGatewayConfig(data);
    }
  } catch (e) {
    log('error', 'gateway_config.load_failed', { error: e.message });
  }
  
  // Return default config if no file exists
  return normalizeGatewayConfig({});
}

// Save gateway config
function saveGatewayConfig(config) {
  try {
    const normalized = normalizeGatewayConfig(config);
    ensureConfigDir();
    fs.writeFileSync(GATEWAY_CONFIG_PATH, JSON.stringify(normalized, null, 2), 'utf-8');
    gatewayConfig = normalized;
    log('info', 'gateway_config.saved', { path: GATEWAY_CONFIG_PATH, active: normalized.active });
    return true;
  } catch (e) {
    log('error', 'gateway_config.save_failed', { error: e.message });
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
  if (keys.length === 0) {
    return { key: 'default', ...DEFAULT_GATEWAY };
  }
  const currentIdx = keys.indexOf(gatewayConfig.active);
  const nextIdx = ((currentIdx >= 0 ? currentIdx : 0) + 1) % keys.length;
  const nextKey = keys[nextIdx];
  setActiveGateway(nextKey);
  return { key: nextKey, ...gatewayConfig.gateways[nextKey] };
}

// Runtime configuration
const cfg = {
  timeoutMs: 9000,
  maxRetries: 1,
  retryBackoffMs: 250,
  healthPollMs: 30000,
  nodePollMs: 45000,
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
  'com.openclaw.v5.route.mode': 'Route',
  'com.openclaw.v5.route.gateway': 'Target',
  'com.openclaw.v5.route.health': 'Best',
  'com.openclaw.v5.setup.wizard': 'Wizard',
  'com.openclaw.v5.dial.model': 'Model',
  'com.openclaw.v5.dial.tts': 'TTS',
  'com.openclaw.v5.dial.agents': 'Agents',
  'com.openclaw.v5.dial.profile': 'Gateway'
};
defaultTitles['com.openclaw.streamdeck.v5.dial.model'] = 'Model';
defaultTitles['com.openclaw.streamdeck.v5.dial.tts'] = 'TTS';
defaultTitles['com.openclaw.streamdeck.v5.dial.agents'] = 'Agents';
defaultTitles['com.openclaw.streamdeck.v5.dial.profile'] = 'Gateway';

// Dial state management
const dialState = {
  models: [
    'openai/gpt-5.2',
    'openai/gpt-5.3-codex',
    'synthetic/hf:minimaxai/minimax-m2.5',
    'synthetic/hf:nvidia/kimi-k2.5-nvfp4'
  ],
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
const ROUTE_MODES = ['global_active', 'fixed_gateway', 'failover_set', 'latency_best', 'role_based'];
const contextSettings = new Map(); // context -> routing/settings
const healthRegistry = {
  gateways: {}, // key -> health
  nodes: {} // key -> { ok, nodeCount, checkedAt, code }
};
let healthPollInterval = null;
let nodePollInterval = null;

function send(obj) {
  if (ws.readyState === WebSocket.OPEN) ws.send(JSON.stringify(obj));
}

function supportsPropertyInspector(action) {
  return typeof action === 'string' && (
    action.startsWith('com.openclaw.v5.') ||
    action.startsWith('com.openclaw.streamdeck.v5.')
  );
}

function buildPropertyInspectorPayload(context, action) {
  const keys = getGatewayKeys();
  return {
    type: 'routing.capabilities.v1',
    action,
    context,
    routeModes: ROUTE_MODES,
    activeGateway: gatewayConfig.active,
    gatewayKeys: keys,
    routeRoles: gatewayConfig.routeRoles || {},
    settings: getContextRouteSettings(context, action)
  };
}

function pushPropertyInspectorPayload(context, action) {
  if (!context || !supportsPropertyInspector(action)) return;
  send({
    event: 'sendToPropertyInspector',
    context,
    action,
    payload: buildPropertyInspectorPayload(context, action)
  });
}

function isDialAction(action) {
  return typeof action === 'string' && (
    action.startsWith('com.openclaw.v5.dial.') ||
    action.startsWith('com.openclaw.streamdeck.v5.dial.')
  );
}

function setTitle(context, title) {
  send({ event: 'setTitle', context, payload: { title, target: 0 } });
}

function showBusy(context, title = '...') { setTitle(context, title); }
function showOk(context, title = 'OK') {
  send({ event: 'showOk', context });
  setTitle(context, title);
}
function showErr(context, title = 'ERR') {
  send({ event: 'showAlert', context });
  setTitle(context, title);
}

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

async function callGateway(path, method = 'GET', body, gatewayOverride = null, options = {}) {
  const gw = gatewayOverride || getCurrentGateway();
  const upperMethod = String(method || 'GET').toUpperCase();
  const retryableMethod = upperMethod === 'GET' || upperMethod === 'HEAD';
  const allowRetry = options.retry === true || (options.retry !== false && retryableMethod);
  const maxRetries = allowRetry ? Math.max(0, Number(cfg.maxRetries || 0)) : 0;
  return invokeGatewayCall({
    gw,
    path,
    method: upperMethod,
    body,
    timeoutMs: cfg.timeoutMs,
    maxRetries,
    retryBackoffMs: cfg.retryBackoffMs,
    errCode,
    recordTelemetry,
    log
  });
}

function persistContextSettings(context, settings) {
  if (!context) return;
  send({
    event: 'setSettings',
    context,
    payload: settings
  });
}

function getContextRouteSettings(context, action) {
  const keys = getGatewayKeys();
  const raw = contextSettings.get(context) || {};
  const normalized = normalizeContextRoutingSettings(raw, keys, gatewayConfig.active);
  if (action === 'com.openclaw.v5.route.mode' || action === 'com.openclaw.v5.route.gateway' || action === 'com.openclaw.v5.route.health') {
    return normalized;
  }
  return normalized;
}

function resolveGatewayForEvent(context, action) {
  const keys = getGatewayKeys();
  const route = getContextRouteSettings(context, action);
  const key = chooseGatewayKey({
    mode: route.routeMode,
    fixedGatewayKey: route.fixedGatewayKey,
    failoverGatewayKeys: route.failoverGatewayKeys,
    activeGatewayKey: gatewayConfig.active,
    availableGatewayKeys: keys,
    healthByGateway: healthRegistry.gateways,
    action,
    roleGatewayMap: gatewayConfig.routeRoles || {}
  });
  if (!key || !gatewayConfig.gateways[key]) {
    return { key: gatewayConfig.active, ...getCurrentGateway(), routeMode: route.routeMode };
  }
  return {
    key,
    url: gatewayConfig.gateways[key].url,
    token: gatewayConfig.gateways[key].token,
    routeMode: route.routeMode
  };
}

function cycleRouteModeForContext(context, action) {
  const current = getContextRouteSettings(context, action);
  const idx = ROUTE_MODES.indexOf(normalizeRouteMode(current.routeMode));
  const nextMode = ROUTE_MODES[((idx >= 0 ? idx : 0) + 1) % ROUTE_MODES.length];
  const next = { ...current, routeMode: nextMode };
  contextSettings.set(context, next);
  persistContextSettings(context, next);
  return next;
}

function cycleFixedGatewayForContext(context, action) {
  const keys = getGatewayKeys();
  if (!keys.length) return null;
  const current = getContextRouteSettings(context, action);
  const idx = keys.indexOf(current.fixedGatewayKey);
  const nextKey = keys[((idx >= 0 ? idx : 0) + 1) % keys.length];
  const next = { ...current, fixedGatewayKey: nextKey };
  contextSettings.set(context, next);
  persistContextSettings(context, next);
  return nextKey;
}

async function chooseBestGatewayKey() {
  const keys = getGatewayKeys();
  if (!keys.length) return null;
  const health = await checkAllGatewaysHealth();
  const healthy = health.filter(h => h && h.ok);
  if (!healthy.length) return null;
  healthy.sort((a, b) => (a.latencyMs || Number.MAX_SAFE_INTEGER) - (b.latencyMs || Number.MAX_SAFE_INTEGER));
  return healthy[0].key;
}

async function pollGatewayNodes(key) {
  const gw = gatewayConfig.gateways[key];
  if (!gw) return;
  const ac = new AbortController();
  const timer = setTimeout(() => ac.abort(), cfg.timeoutMs);
  try {
    const r = await fetch(`${gw.url}/nodes.status`, {
      method: 'GET',
      headers: gw.token ? { authorization: `Bearer ${gw.token}` } : {},
      signal: ac.signal
    });
    let data = {};
    try { data = await r.json(); } catch {}
    const nodeCount = Array.isArray(data?.nodes) ? data.nodes.length : 0;
    healthRegistry.nodes[key] = {
      ok: r.ok,
      nodeCount,
      checkedAt: Date.now(),
      code: r.ok ? 'OK' : errCode({ status: r.status })
    };
  } catch (e) {
    healthRegistry.nodes[key] = {
      ok: false,
      nodeCount: 0,
      checkedAt: Date.now(),
      code: 'OFF'
    };
  } finally {
    clearTimeout(timer);
  }
}

async function pollAllGatewayNodes() {
  const keys = getGatewayKeys();
  await Promise.all(keys.map(k => pollGatewayNodes(k)));
}

function startHealthPollers() {
  if (!healthPollInterval) {
    healthPollInterval = setInterval(() => {
      checkAllGatewaysHealth().catch(() => {});
    }, cfg.healthPollMs);
  }
  if (!nodePollInterval) {
    nodePollInterval = setInterval(() => {
      pollAllGatewayNodes().catch(() => {});
    }, cfg.nodePollMs);
  }
}

// Check gateway health
async function checkGatewayHealth(key) {
  const now = Date.now();
  const cached = dialState.gatewayHealth[key];
  
  // Return cached if recent
  if (cached && (now - cached.checkedAt) < HEALTH_CACHE_MS) {
    healthRegistry.gateways[key] = cached;
    return cached;
  }
  
  const gw = gatewayConfig.gateways[key];
  if (!gw) return { ok: false, latencyMs: 0, checkedAt: now, key };
  
  const start = Date.now();
  const ac = new AbortController();
  const timer = setTimeout(() => ac.abort(), cfg.timeoutMs);
  try {
    const r = await fetch(`${gw.url}/status`, {
      method: 'GET',
      headers: gw.token ? { 'authorization': `Bearer ${gw.token}` } : {},
      signal: ac.signal
    });
    
    const latencyMs = Date.now() - start;
    const result = { 
      ok: r.ok, 
      latencyMs, 
      checkedAt: now, 
      key,
      code: r.ok ? 'OK' : errCode({ ok: r.ok, status: r.status })
    };
    dialState.gatewayHealth[key] = result;
    healthRegistry.gateways[key] = result;
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
    healthRegistry.gateways[key] = result;
    return result;
  } finally {
    clearTimeout(timer);
  }
}

// Check all gateways health
async function checkAllGatewaysHealth() {
  const keys = getGatewayKeys();
  const results = await Promise.all(keys.map(k => checkGatewayHealth(k)));
  return results;
}

function backToDefault(context, action) {
  setTimeout(() => setTitle(context, defaultTitles[action] || 'Ready'), 2800);
}

function getContextSettingString(context, key, fallback = '', maxLen = 240) {
  const settings = contextSettings.get(context) || {};
  const raw = settings && typeof settings[key] === 'string' ? settings[key].trim() : '';
  if (!raw) return fallback;
  return raw.slice(0, maxLen);
}

function getContextSettingNumber(context, key, fallback, min, max) {
  const settings = contextSettings.get(context) || {};
  const parsed = Number(settings ? settings[key] : NaN);
  if (!Number.isFinite(parsed)) return fallback;
  const rounded = Math.floor(parsed);
  return Math.max(min, Math.min(max, rounded));
}

function syncGatewayTokenFromOpenClawConfig() {
  try {
    if (!fs.existsSync(OPENCLAW_CONFIG_PATH)) {
      return { ok: false, code: 'NOCFG', changed: false };
    }
    const cfg = readJsonFileSafe(OPENCLAW_CONFIG_PATH);
    const token = typeof cfg?.gateway?.auth?.token === 'string' ? cfg.gateway.auth.token.trim() : '';
    if (!token) {
      return { ok: false, code: 'NOTOK', changed: false };
    }
    let changed = false;
    for (const key of Object.keys(gatewayConfig.gateways || {})) {
      if (!gatewayConfig.gateways[key]) continue;
      if (gatewayConfig.gateways[key].token !== token) {
        gatewayConfig.gateways[key].token = token;
        changed = true;
      }
    }
    if (changed) {
      saveGatewayConfig(gatewayConfig);
      log('info', 'setup.token_synced', { gateways: Object.keys(gatewayConfig.gateways || {}) });
    }
    return { ok: true, code: changed ? 'SYNC' : 'OK', changed };
  } catch (e) {
    log('error', 'setup.token_sync_failed', { error: e.message });
    return { ok: false, code: 'ERR', changed: false };
  }
}

function launchSetupWizard() {
  const tokenSync = syncGatewayTokenFromOpenClawConfig();
  try {
    if (fs.existsSync(LOCAL_SETUP_WIZARD_PATH)) {
      spawn('cmd.exe', ['/c', 'start', '""', LOCAL_SETUP_WIZARD_PATH], { detached: true, stdio: 'ignore' }).unref();
      return { ok: true, code: tokenSync.changed ? 'SYNC' : 'OPEN' };
    }
    const workspace = path.join(process.env.USERPROFILE || process.env.HOME, '.openclaw', 'workspace', 'skills', 'streamdeck', 'web-dashboard');
    const startBat = path.join(workspace, 'START-SERVER.bat');
    spawn('cmd.exe', ['/c', 'start', '""', startBat, '8787'], { detached: true, stdio: 'ignore' }).unref();
    spawn('cmd.exe', ['/c', 'start', '""', 'http://localhost:8787/wizard'], { detached: true, stdio: 'ignore' }).unref();
    return { ok: true, code: tokenSync.changed ? 'SYNC' : 'OPEN' };
  } catch (e) {
    log('error', 'setup_wizard.launch_failed', { error: e.message });
    return { ok: false, code: tokenSync.ok ? 'ERR' : tokenSync.code || 'ERR' };
  }
}

async function handleKeyUp(evt) {
  const { context, action } = evt;
  log('info', 'key.up', { action, context });
  showBusy(context);
  const routeGw = resolveGatewayForEvent(context, action);

  if (action === 'com.openclaw.v5.status' || action === 'com.openclaw.v5.reconnect') {
    const res = await callGateway('/status', 'GET', undefined, routeGw);
    if (res.ok) {
      const latency = String(res.latencyMs ?? 'OK');
      showOk(context, latency.slice(0, 4));
    } else showErr(context, errCode(res));
    return backToDefault(context, action);
  }

  if (action === 'com.openclaw.v5.tts') {
    const nextMuted = !dialState.ttsMuted;
    const res = await callGateway(nextMuted ? '/tts.disable' : '/tts.enable', 'POST', {}, routeGw, { retry: false });
    if (res.ok) {
      dialState.ttsMuted = nextMuted;
      const label = dialState.ttsMuted ? 'OFF' : 'ON';
      showOk(context, label);
      recordTelemetry('key.tts.toggle', 'ok', Number(res.latencyMs || 0), 'OK', { muted: dialState.ttsMuted });
    } else {
      showErr(context, errCode(res));
      recordTelemetry('key.tts.toggle', 'err', Number(res.latencyMs || 0), errCode(res), { muted: dialState.ttsMuted });
    }
    return backToDefault(context, action);
  }

  if (action === 'com.openclaw.v5.spawn') {
    const sessionKey = getContextSettingString(context, 'sessionKey', 'agent:main:main', 120);
    const task = getContextSettingString(context, 'spawnTask', 'Quick assistance', 320);
    const res = await callGateway('/spawn', 'POST', {
      task,
      sessionKey,
      deliver: true
    }, routeGw, { retry: false });
    if (res.ok) showOk(context, 'SPWN');
    else showErr(context, errCode(res));
    return backToDefault(context, action);
  }

  if (action === 'com.openclaw.v5.session') {
    const res = await callGateway('/session.status', 'GET', undefined, routeGw);
    if (res.ok) {
      const sessionCount = Array.isArray(res.data?.sessions) ? res.data.sessions.length : null;
      if (sessionCount !== null) {
        showOk(context, `${sessionCount}`);
      } else {
        const model = String(res.data?.model || 'OK').split('/').pop();
        showOk(context, model.slice(0, 4));
      }
    } else showErr(context, errCode(res));
    return backToDefault(context, action);
  }

  if (action === 'com.openclaw.v5.subagents') {
    const res = await callGateway('/subagents.list', 'GET', undefined, routeGw);
    if (res.ok) {
      const count = Array.isArray(res.data?.agents) ? res.data.agents.length : 0;
      showOk(context, `${count}`);
    } else showErr(context, errCode(res));
    return backToDefault(context, action);
  }

  if (action === 'com.openclaw.v5.nodes') {
    const res = await callGateway('/nodes.status', 'GET', undefined, routeGw);
    if (res.ok) {
      const count = Array.isArray(res.data?.nodes) ? res.data.nodes.length : 0;
      showOk(context, `${count}`);
    } else showErr(context, errCode(res));
    return backToDefault(context, action);
  }

  if (action === 'com.openclaw.v5.websearch') {
    const sessionKey = getContextSettingString(context, 'sessionKey', 'agent:main:main', 120);
    const query = getContextSettingString(context, 'searchQuery', cfg.defaultSearch, 200);
    const count = getContextSettingNumber(context, 'searchCount', 3, 1, 10);
    const res = await callGateway('/web.search', 'POST', {
      query,
      count,
      sessionKey,
      deliver: true
    }, routeGw, { retry: false });
    if (res.ok) showOk(context, 'FND');
    else showErr(context, errCode(res));
    return backToDefault(context, action);
  }

  if (action === 'com.openclaw.v5.setup.wizard') {
    const setup = launchSetupWizard();
    if (setup.ok) showOk(context, setup.code || 'OPEN');
    else showErr(context, setup.code || 'ERR');
    return backToDefault(context, action);
  }

  if (action === 'com.openclaw.v5.route.mode') {
    const next = cycleRouteModeForContext(context, action);
    showOk(context, next.routeMode.slice(0, 4).toUpperCase());
    return backToDefault(context, action);
  }

  if (action === 'com.openclaw.v5.route.gateway') {
    const key = cycleFixedGatewayForContext(context, action);
    if (!key) {
      showErr(context, 'NOGW');
      return backToDefault(context, action);
    }
    const health = await checkGatewayHealth(key);
    if (health.ok) showOk(context, key.slice(0, 4).toUpperCase());
    else showErr(context, health.code || 'OFF');
    return backToDefault(context, action);
  }

  if (action === 'com.openclaw.v5.route.health') {
    const bestKey = await chooseBestGatewayKey();
    if (!bestKey) {
      showErr(context, 'OFF');
      return backToDefault(context, action);
    }
    setActiveGateway(bestKey);
    const current = getContextRouteSettings(context, action);
    const next = { ...current, fixedGatewayKey: bestKey };
    contextSettings.set(context, next);
    persistContextSettings(context, next);
    showOk(context, bestKey.slice(0, 4).toUpperCase());
    return backToDefault(context, action);
  }

  // Gateway Switcher v1: Next Gateway key action
  if (action === 'com.openclaw.v5.gateway.next') {
    const keys = getGatewayKeys();
    if (keys.length <= 1) {
      showOk(context, '1 GW');
      return backToDefault(context, action);
    }
    
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

// Set raw feedback with direct payload (for animation frames)
function setFeedbackRaw(context, payload) {
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
  const routeGw = resolveGatewayForEvent(context, 'com.openclaw.v5.dial.model');
  const model = dialState.models[dialState.modelIndex];
  setFeedback(context, { title: '...', value: 'Apply' });
  setAnimState(context, 'busy');
  const start = Date.now();
  const res = await callGateway('/session.set', 'POST', { model }, routeGw, { retry: false });
  const latencyMs = Date.now() - start;
  const code = res.ok ? 'OK' : errCode(res);
  recordTelemetry('dial.model.apply', res.ok ? 'ok' : 'err', latencyMs, code, { model });
  const short = model.split('/').pop().slice(0, 6);
  if (res.ok) {
    setAnimState(context, 'success');
  } else {
    setAnimState(context, 'error');
  }
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
  const routeGw = resolveGatewayForEvent(context, 'com.openclaw.v5.dial.tts');
  const nextMuted = !dialState.ttsMuted;
  const endpoint = nextMuted ? '/tts.disable' : '/tts.enable';
  setAnimState(context, 'busy');
  const res = await callGateway(endpoint, 'POST', {}, routeGw, { retry: false });
  if (res.ok) {
    dialState.ttsMuted = nextMuted;
  }
  const vol = dialState.ttsMuted ? 'MUTED' : `${dialState.ttsVolume}%`;
  if (res.ok) {
    setAnimState(context, 'success');
    setFeedback(context, { title: dialState.ttsMuted ? 'OFF' : 'ON', value: vol });
    recordTelemetry('dial.tts.toggle', 'ok', Number(res.latencyMs || 0), 'OK', { muted: dialState.ttsMuted, volume: dialState.ttsVolume });
  } else {
    setAnimState(context, 'error');
    const code = errCode(res);
    setFeedback(context, { title: code, value: vol });
    recordTelemetry('dial.tts.toggle', 'err', Number(res.latencyMs || 0), code, { muted: dialState.ttsMuted, volume: dialState.ttsVolume });
  }
}

// Dial 3: Session/subagent navigator
async function handleAgentsDial(evt) {
  const { context, payload } = evt;
  const routeGw = resolveGatewayForEvent(context, 'com.openclaw.v5.dial.agents');
  const { ticks } = payload || {};
  setAnimState(context, 'busy');
  const start = Date.now();
  const res = await callGateway('/subagents.list', 'GET', undefined, routeGw);
  const latencyMs = Date.now() - start;
  dialState.agents = Array.isArray(res.data?.agents) ? res.data.agents : [];
  const len = Math.max(1, dialState.agents.length);
  if (ticks) {
    dialState.agentIndex = ((dialState.agentIndex + ticks) % len + len) % len;
  }
  const agent = dialState.agents[dialState.agentIndex];
  const name = agent?.name?.slice(0, 8) || `(${dialState.agentIndex + 1}/${len})`;
  setAnimState(context, 'idle');
  setFeedback(context, { title: 'Agent', value: name });
}

async function handleAgentsDialPress(evt) {
  const { context } = evt;
  const routeGw = resolveGatewayForEvent(context, 'com.openclaw.v5.dial.agents');
  const agent = dialState.agents[dialState.agentIndex];
  if (!agent?.id) {
    setFeedback(context, { title: 'Agent', value: 'None' });
    return;
  }
  setFeedback(context, { title: '...', value: 'Kill' });
  setAnimState(context, 'busy');
  const res = await callGateway('/subagents.kill', 'POST', { target: agent.id }, routeGw, { retry: false });
  if (res.ok) {
    setAnimState(context, 'success');
  } else {
    setAnimState(context, 'error');
  }
  setFeedback(context, { title: res.ok ? 'OK' : errCode(res), value: agent.name?.slice(0, 6) || '?' });
}

// Dial 4: Gateway profile switch + ping press (Gateway Switcher v1)
async function handleProfileDial(evt) {
  const { context, payload } = evt;
  const { ticks } = payload || {};
  const keys = getGatewayKeys();
  const len = keys.length;
  if (len === 0) {
    setFeedback(context, { title: 'ERR', value: 'No GW' });
    return;
  }
  
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
  if (keys.length === 0) {
    setAnimState(context, 'error');
    setFeedback(context, { title: 'ERR', value: 'No GW' });
    return;
  }
  const currentIdx = keys.indexOf(gatewayConfig.active);
  const nextIdx = ((currentIdx >= 0 ? currentIdx : 0) + 1) % keys.length;
  const nextKey = keys[nextIdx];
  
  setFeedback(context, { title: '...', value: 'Apply' });
  setAnimState(context, 'busy');
  
  // Apply the gateway
  if (setActiveGateway(nextKey)) {
    // Ping to verify
    const health = await checkGatewayHealth(nextKey);
    if (health.ok) {
      setAnimState(context, 'success');
    } else {
      setAnimState(context, 'error');
    }
    const latency = health.ok ? `${health.latencyMs}ms` : health.code;
    setFeedback(context, { title: nextKey, value: latency });
  } else {
    setAnimState(context, 'error');
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

// Export telemetry summary for dashboard access
function exportTelemetryForDashboard() {
  try {
    const summary = getTelemetrySummary();
    const data = {
      ...summary,
      exportedAt: Date.now(),
      version: '1.1'
    };
    ensureConfigDir();
    fs.writeFileSync(TELEMETRY_EXPORT_PATH, JSON.stringify(data, null, 2), 'utf-8');
  } catch (e) {
    log('error', 'telemetry.export_failed', { error: e.message });
  }
}

// Export telemetry periodically (every 10s)
const telemetryExportInterval = setInterval(exportTelemetryForDashboard, TELEMETRY_EXPORT_INTERVAL_MS);

ws.addEventListener('open', () => {
  send({ event: REGISTER_EVENT, uuid: PLUGIN_UUID });
  startHealthPollers();
  checkAllGatewaysHealth().catch(() => {});
  pollAllGatewayNodes().catch(() => {});
  log('info', 'plugin.registered', {
    activeGateway: gatewayConfig.active,
    gateways: Object.keys(gatewayConfig.gateways),
    lobsterAnimator: LOBSTER_ANIM_ENABLED
  });
});

ws.addEventListener('message', async (event) => {
  let evt;
  try { evt = JSON.parse(String(event.data)); } catch { return; }
  log('info', 'ws.event', { event: evt.event, action: evt.action || null, context: evt.context || null });
  try {

  if (evt.event === 'willAppear') {
    const title = defaultTitles[evt.action] || 'Ready';
    const incomingSettings = evt.payload?.settings || {};
    contextSettings.set(evt.context, {
      ...contextSettings.get(evt.context),
      ...incomingSettings
    });
    setTitle(evt.context, title);
    if (evt.action === 'com.openclaw.v5.route.mode') {
      const route = getContextRouteSettings(evt.context, evt.action);
      setTitle(evt.context, route.routeMode.slice(0, 4).toUpperCase());
    }
    
    // Track dashboard actions (Status key can serve as dashboard)
    if (evt.action === 'com.openclaw.v5.status') {
      dashboardContext = evt.context;
      dashboardAction = evt.action;
      // Update with current gateway info
      updateDashboardGatewayInfo();
    }
    
    // Initialize Lobster Animator for dial actions
    if (LOBSTER_ANIM_ENABLED && isDialAction(evt.action)) {
      const anim = getAnim(evt.context, 'idle');
      if (anim) anim.start();
    }
    pushPropertyInspectorPayload(evt.context, evt.action);
    
    return;
  }

  if (evt.event === 'willDisappear') {
    if (evt.context === dashboardContext) {
      dashboardContext = null;
      dashboardAction = null;
    }
    contextSettings.delete(evt.context);
    
    // Clean up Lobster Animator for dial actions
    if (isDialAction(evt.action)) {
      destroyAnim(evt.context);
    }
    
    return;
  }

  if (evt.event === 'keyUp') {
    await handleKeyUp(evt);
    return;
  }

  if (evt.event === 'dialRotate') {
    const action = evt.action;
    if (action === 'com.openclaw.v5.dial.model' || action === 'com.openclaw.streamdeck.v5.dial.model') await handleModelDial(evt);
    else if (action === 'com.openclaw.v5.dial.tts' || action === 'com.openclaw.streamdeck.v5.dial.tts') await handleTtsDial(evt);
    else if (action === 'com.openclaw.v5.dial.agents' || action === 'com.openclaw.streamdeck.v5.dial.agents') await handleAgentsDial(evt);
    else if (action === 'com.openclaw.v5.dial.profile' || action === 'com.openclaw.streamdeck.v5.dial.profile') await handleProfileDial(evt);
    return;
  }

  if (evt.event === 'dialUp') {
    const action = evt.action;
    if (action === 'com.openclaw.v5.dial.model' || action === 'com.openclaw.streamdeck.v5.dial.model') await handleModelDialPress(evt);
    else if (action === 'com.openclaw.v5.dial.tts' || action === 'com.openclaw.streamdeck.v5.dial.tts') await handleTtsDialPress(evt);
    else if (action === 'com.openclaw.v5.dial.agents' || action === 'com.openclaw.streamdeck.v5.dial.agents') await handleAgentsDialPress(evt);
    else if (action === 'com.openclaw.v5.dial.profile' || action === 'com.openclaw.streamdeck.v5.dial.profile') await handleProfileDialPress(evt);
    return;
  }

  if (evt.event === 'didReceiveSettings') {
    const s = evt.payload?.settings || {};
    const ctx = evt.context;
    const hasSetting = (key) => Object.prototype.hasOwnProperty.call(s, key);
    let configDirty = false;
    if (!gatewayConfig.routeRoles || typeof gatewayConfig.routeRoles !== 'object') {
      gatewayConfig.routeRoles = {};
      configDirty = true;
    }
    if (ctx) {
      contextSettings.set(ctx, {
        ...contextSettings.get(ctx),
        ...s
      });
    }

    // Support for per-action gateway override in settings.
    const activeGateway = gatewayConfig.gateways[gatewayConfig.active];
    if (hasSetting('gatewayUrl')) {
      const nextGatewayUrl = String(s.gatewayUrl || '').trim();
      if (nextGatewayUrl) {
        const normalized = normalizeGatewayEntry({ url: nextGatewayUrl, token: null });
        if (normalized && activeGateway && activeGateway.url !== normalized.url) {
          activeGateway.url = normalized.url;
          configDirty = true;
        }
      }
    }
    if (hasSetting('gatewayToken') && activeGateway) {
      const nextToken = String(s.gatewayToken || '').trim() || null;
      if (activeGateway.token !== nextToken) {
        activeGateway.token = nextToken;
        configDirty = true;
      }
    }
    if (hasSetting('timeoutMs')) {
      const timeout = Number(s.timeoutMs);
      if (Number.isFinite(timeout) && timeout >= 1000 && timeout <= 30000) {
        cfg.timeoutMs = timeout;
      }
    }
    if (hasSetting('maxRetries')) {
      const maxRetries = Number(s.maxRetries);
      if (Number.isInteger(maxRetries) && maxRetries >= 0 && maxRetries <= 3) {
        cfg.maxRetries = maxRetries;
      }
    }
    if (hasSetting('retryBackoffMs')) {
      const retryBackoffMs = Number(s.retryBackoffMs);
      if (Number.isFinite(retryBackoffMs) && retryBackoffMs >= 50 && retryBackoffMs <= 2000) {
        cfg.retryBackoffMs = retryBackoffMs;
      }
    }
    if (hasSetting('defaultSearch')) {
      const search = String(s.defaultSearch || '').trim();
      if (search) cfg.defaultSearch = search.slice(0, 200);
    }
    if (hasSetting('routeRoleDefault') && gatewayConfig.gateways[s.routeRoleDefault] && gatewayConfig.routeRoles.default !== s.routeRoleDefault) {
      gatewayConfig.routeRoles.default = s.routeRoleDefault;
      configDirty = true;
    }
    if (hasSetting('routeRoleResearch') && gatewayConfig.gateways[s.routeRoleResearch] && gatewayConfig.routeRoles.research !== s.routeRoleResearch) {
      gatewayConfig.routeRoles.research = s.routeRoleResearch;
      configDirty = true;
    }
    if (hasSetting('routeRoleAgents') && gatewayConfig.gateways[s.routeRoleAgents] && gatewayConfig.routeRoles.agents !== s.routeRoleAgents) {
      gatewayConfig.routeRoles.agents = s.routeRoleAgents;
      configDirty = true;
    }
    if (hasSetting('routeRoleAudio') && gatewayConfig.gateways[s.routeRoleAudio] && gatewayConfig.routeRoles.audio !== s.routeRoleAudio) {
      gatewayConfig.routeRoles.audio = s.routeRoleAudio;
      configDirty = true;
    }
    if (hasSetting('routeRoleSession') && gatewayConfig.gateways[s.routeRoleSession] && gatewayConfig.routeRoles.session !== s.routeRoleSession) {
      gatewayConfig.routeRoles.session = s.routeRoleSession;
      configDirty = true;
    }
    if (hasSetting('routeRoleNodes') && gatewayConfig.gateways[s.routeRoleNodes] && gatewayConfig.routeRoles.nodes !== s.routeRoleNodes) {
      gatewayConfig.routeRoles.nodes = s.routeRoleNodes;
      configDirty = true;
    }

    if (configDirty) {
      saveGatewayConfig(gatewayConfig);
    }

    if (ctx) {
      pushPropertyInspectorPayload(ctx, evt.action);
    }
    return;
  }

  if (evt.event === 'propertyInspectorDidAppear') {
    pushPropertyInspectorPayload(evt.context, evt.action);
    return;
  }
  } catch (e) {
    log('error', 'ws.event_handler_failed', {
      event: evt?.event || null,
      action: evt?.action || null,
      context: evt?.context || null,
      error: e?.message || String(e)
    });
  }
});

function gracefulShutdown(exitCode) {
  try {
    if (telemetryExportTimer) {
      clearTimeout(telemetryExportTimer);
      telemetryExportTimer = null;
    }
    if (telemetryFlushTimer) {
      clearTimeout(telemetryFlushTimer);
      telemetryFlushTimer = null;
    }
    if (healthPollInterval) {
      clearInterval(healthPollInterval);
      healthPollInterval = null;
    }
    if (nodePollInterval) {
      clearInterval(nodePollInterval);
      nodePollInterval = null;
    }
    clearInterval(telemetryExportInterval);
    flushTelemetry();
    exportTelemetryForDashboard();
    for (const anim of lobsterAnims.values()) {
      anim.destroy();
    }
  } catch (e) {
    log('error', 'shutdown.cleanup_failed', { error: e.message });
  } finally {
    process.exit(exitCode);
  }
}

ws.addEventListener('close', () => gracefulShutdown(0));
ws.addEventListener('error', (e) => {
  log('error', 'ws.error', { error: e?.message || String(e) });
  gracefulShutdown(1);
});
