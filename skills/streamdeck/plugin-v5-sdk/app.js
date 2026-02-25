/* OpenClaw Stream Deck SDK v5 runtime with Dial Pack v1 */
// Node 22+ (global fetch + WebSocket)
// Dial Pack: 4 encoder actions - Model, TTS, Agents, Profile

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

const cfg = {
  gateway: 'http://127.0.0.1:18790',
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
  'com.openclaw.v5.dial.model': 'Model',
  'com.openclaw.v5.dial.tts': 'TTS',
  'com.openclaw.v5.dial.agents': 'Agents',
  'com.openclaw.v5.dial.profile': 'Profile'
};

// Dial state management
const dialState = {
  models: ['synthetic/hf:nvidia/Kimi-K2.5-NVFP4', 'synthetic/vertex/gemini-2.5-pro', 'anthropic/claude-3.5-sonnet', 'openai/gpt-4o'],
  modelIndex: 0,
  ttsVolume: 100,
  ttsMuted: false,
  agents: [],
  agentIndex: 0,
  profiles: ['default', 'coding', 'gaming', 'media'],
  profileIndex: 0
};

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
    if (msg.includes('abort')) return 'TIME';
    return 'OFF';
  }
  return 'ERR';
}

async function callGateway(path, method = 'GET', body) {
  console.log('[openclaw-v5] api', method, path);
  const ac = new AbortController();
  const t = setTimeout(() => ac.abort(), cfg.timeoutMs);
  try {
    const r = await fetch(`${cfg.gateway}${path}`, {
      method,
      headers: { 'content-type': 'application/json' },
      body: body ? JSON.stringify(body) : undefined,
      signal: ac.signal
    });
    const text = await r.text();
    let data;
    try { data = text ? JSON.parse(text) : {}; } catch { data = { raw: text }; }
    return { ok: r.ok, status: r.status, data };
  } catch (e) {
    return { ok: false, status: 0, data: { error: String(e) } };
  } finally {
    clearTimeout(t);
  }
}

function backToDefault(context, action) {
  setTimeout(() => setTitle(context, defaultTitles[action] || 'Ready'), 1800);
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
  setFeedback(context, { title: res.ok ? 'OK' : 'ERR', value: short });
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
  setFeedback(context, { title: res.ok ? 'OK' : 'ERR', value: agent.name?.slice(0, 6) || '?' });
}

// Dial 4: Gateway profile switch + ping press
async function handleProfileDial(evt) {
  const { context, payload } = evt;
  const { ticks } = payload || {};
  const len = dialState.profiles.length;
  if (ticks) {
    dialState.profileIndex = ((dialState.profileIndex + ticks) % len + len) % len;
  }
  const prof = dialState.profiles[dialState.profileIndex];
  setFeedback(context, { title: 'Profile', value: prof });
}

async function handleProfileDialPress(evt) {
  const { context } = evt;
  const prof = dialState.profiles[dialState.profileIndex];
  setFeedback(context, { title: '...', value: 'Ping' });
  const res = await callGateway('/status');
  const latency = res.data?.latencyMs ? `${res.data.latencyMs}ms` : (res.ok ? 'OK' : 'ERR');
  setFeedback(context, { title: prof, value: latency });
}

ws.addEventListener('open', () => {
  send({ event: REGISTER_EVENT, uuid: PLUGIN_UUID });
  console.log('[openclaw-v5] registered');
});

ws.addEventListener('message', async (event) => {
  let evt;
  try { evt = JSON.parse(String(event.data)); } catch { return; }
  try { console.log('[openclaw-v5] evt', evt.event, evt.action || '', evt.context || ''); } catch {}

  if (evt.event === 'willAppear') {
    setTitle(evt.context, defaultTitles[evt.action] || 'Ready');
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
    if (s.gateway) cfg.gateway = String(s.gateway);
    if (s.timeoutMs) cfg.timeoutMs = Number(s.timeoutMs) || cfg.timeoutMs;
    if (s.defaultSearch) cfg.defaultSearch = String(s.defaultSearch);
  }
});

ws.addEventListener('close', () => process.exit(0));
ws.addEventListener('error', (e) => {
  console.error('[openclaw-v5] ws error', e?.message || e);
  process.exit(1);
});
