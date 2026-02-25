/* OpenClaw Stream Deck SDK v5 runtime (foundation) */
// Uses global WebSocket in Node 22+

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

const actionByContext = new Map();

const cfg = {
  gateway: 'http://127.0.0.1:18790',
  timeoutMs: 9000
};

async function callGateway(path, method = 'GET', body) {
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

function send(obj) {
  if (ws.readyState === WebSocket.OPEN) ws.send(JSON.stringify(obj));
}

function setTitle(context, title) {
  send({ event: 'setTitle', context, payload: { title, target: 0 } });
}

function showOk(context, title = 'OK') { setTitle(context, title); }
function showErr(context, title = 'ERR') { setTitle(context, title); }
function showBusy(context, title = '...') { setTitle(context, title); }

async function handleKeyUp(evt) {
  const { context, action } = evt;
  showBusy(context);

  if (action === 'com.openclaw.v5.status') {
    const res = await callGateway('/status');
    if (res.ok) {
      const latency = res.data?.latencyMs ?? 'OK';
      showOk(context, `${latency}`.slice(0, 4));
    } else {
      showErr(context, 'OFF');
    }
    return;
  }

  if (action === 'com.openclaw.v5.tts') {
    const getRes = await callGateway('/config.get');
    const enabled = !!(getRes.data?.messages?.tts?.enabled);
    const setRes = await callGateway('/config.patch', 'POST', { path: 'messages.tts.enabled', value: !enabled });
    if (setRes.ok) showOk(context, !enabled ? 'ON' : 'OFF');
    else showErr(context);
    return;
  }

  if (action === 'com.openclaw.v5.spawn') {
    const res = await callGateway('/spawn', 'POST', { task: 'Quick assistance', agentId: 'helper' });
    if (res.ok) showOk(context, 'SPWN');
    else showErr(context);
    return;
  }

  showErr(context, '?');
}

ws.addEventListener('open', () => {
  send({ event: REGISTER_EVENT, uuid: PLUGIN_UUID });
  console.log('[openclaw-v5] registered');
});

ws.addEventListener('message', async (event) => {
  let evt;
  try { evt = JSON.parse(String(event.data)); } catch { return; }

  if (evt.event === 'willAppear') {
    actionByContext.set(evt.context, evt.action);
    setTitle(evt.context, 'Ready');
    return;
  }

  if (evt.event === 'keyUp') {
    await handleKeyUp(evt);
    return;
  }

  if (evt.event === 'didReceiveSettings') {
    const s = evt.payload?.settings || {};
    if (s.gateway) cfg.gateway = String(s.gateway);
    if (s.timeoutMs) cfg.timeoutMs = Number(s.timeoutMs) || cfg.timeoutMs;
  }
});

ws.addEventListener('close', () => process.exit(0));
ws.addEventListener('error', (e) => {
  console.error('[openclaw-v5] ws error', e?.message || e);
  process.exit(1);
});
