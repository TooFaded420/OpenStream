function normalizeRouteMode(mode) {
  const supported = new Set(['global_active', 'fixed_gateway', 'failover_set', 'latency_best', 'role_based']);
  const value = typeof mode === 'string' ? mode.trim().toLowerCase() : '';
  return supported.has(value) ? value : 'global_active';
}

function parseFailoverKeys(input) {
  const raw = Array.isArray(input)
    ? input.map(String)
    : (typeof input === 'string' ? input.split(',') : []);
  const out = [];
  const seen = new Set();
  for (const item of raw) {
    const key = String(item).trim();
    if (!key || seen.has(key)) continue;
    seen.add(key);
    out.push(key);
  }
  return out;
}

function actionRole(action) {
  if (!action) return 'default';
  if (action.includes('.tts') || action.includes('.audio')) return 'audio';
  if (action.includes('.websearch') || action.includes('.search')) return 'research';
  if (action.includes('.spawn') || action.includes('.agents') || action.includes('.subagents')) return 'agents';
  if (action.includes('.session') || action.includes('.model')) return 'session';
  if (action.includes('.nodes')) return 'nodes';
  return 'default';
}

function pickHealthyWithLowestLatency(keys, healthByGateway) {
  const healthy = keys
    .map(k => ({ key: k, health: healthByGateway[k] }))
    .filter(x => x.health && x.health.ok === true)
    .sort((a, b) => (a.health.latencyMs || Number.MAX_SAFE_INTEGER) - (b.health.latencyMs || Number.MAX_SAFE_INTEGER));
  return healthy.length ? healthy[0].key : null;
}

function pickFirstHealthy(keys, healthByGateway) {
  for (const key of keys) {
    const h = healthByGateway[key];
    if (h && h.ok === true) return key;
  }
  return null;
}

function chooseGatewayKey(params) {
  const {
    mode,
    fixedGatewayKey,
    failoverGatewayKeys,
    activeGatewayKey,
    availableGatewayKeys,
    healthByGateway,
    action,
    roleGatewayMap
  } = params;

  const keys = Array.isArray(availableGatewayKeys) ? availableGatewayKeys : [];
  const active = keys.includes(activeGatewayKey) ? activeGatewayKey : keys[0];
  if (!keys.length) return null;

  const routeMode = normalizeRouteMode(mode);

  if (routeMode === 'fixed_gateway') {
    return keys.includes(fixedGatewayKey) ? fixedGatewayKey : active;
  }

  if (routeMode === 'failover_set') {
    const pool = parseFailoverKeys(failoverGatewayKeys).filter(k => keys.includes(k));
    if (!pool.length) return active;
    return pickFirstHealthy(pool, healthByGateway) || active || pool[0];
  }

  if (routeMode === 'latency_best') {
    return pickHealthyWithLowestLatency(keys, healthByGateway) || active;
  }

  if (routeMode === 'role_based') {
    const role = actionRole(action);
    const byRole = roleGatewayMap && typeof roleGatewayMap === 'object' ? roleGatewayMap[role] : null;
    if (byRole && keys.includes(byRole)) return byRole;
    const fallbackRole = roleGatewayMap && typeof roleGatewayMap === 'object' ? roleGatewayMap.default : null;
    if (fallbackRole && keys.includes(fallbackRole)) return fallbackRole;
    return active;
  }

  return active;
}

function normalizeContextRoutingSettings(settings, availableGatewayKeys, activeGatewayKey) {
  const keys = Array.isArray(availableGatewayKeys) ? availableGatewayKeys : [];
  const active = keys.includes(activeGatewayKey) ? activeGatewayKey : keys[0];
  const mode = normalizeRouteMode(settings?.routeMode || settings?.gatewayRouteMode);
  const fixedGatewayKey = keys.includes(settings?.fixedGatewayKey) ? settings.fixedGatewayKey : active;
  const failoverGatewayKeys = parseFailoverKeys(settings?.failoverGatewayKeys || settings?.failoverSet).filter(k => keys.includes(k));
  return {
    routeMode: mode,
    fixedGatewayKey: fixedGatewayKey || active || null,
    failoverGatewayKeys
  };
}

module.exports = {
  normalizeRouteMode,
  parseFailoverKeys,
  actionRole,
  chooseGatewayKey,
  normalizeContextRoutingSettings
};
