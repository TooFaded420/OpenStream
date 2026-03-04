const test = require('node:test');
const assert = require('node:assert/strict');
const { chooseGatewayKey, normalizeContextRoutingSettings } = require('../lib/routing');

const health = {
  a: { ok: true, latencyMs: 80 },
  b: { ok: true, latencyMs: 20 },
  c: { ok: false, latencyMs: 0 }
};

test('global_active returns active gateway', () => {
  const key = chooseGatewayKey({
    mode: 'global_active',
    activeGatewayKey: 'a',
    availableGatewayKeys: ['a', 'b', 'c'],
    healthByGateway: health,
    action: 'com.openclaw.v5.status',
    roleGatewayMap: {}
  });
  assert.equal(key, 'a');
});

test('fixed_gateway returns configured gateway', () => {
  const key = chooseGatewayKey({
    mode: 'fixed_gateway',
    fixedGatewayKey: 'b',
    activeGatewayKey: 'a',
    availableGatewayKeys: ['a', 'b', 'c'],
    healthByGateway: health,
    action: 'com.openclaw.v5.status',
    roleGatewayMap: {}
  });
  assert.equal(key, 'b');
});

test('failover_set picks first healthy from pool', () => {
  const key = chooseGatewayKey({
    mode: 'failover_set',
    failoverGatewayKeys: ['c', 'b', 'a'],
    activeGatewayKey: 'a',
    availableGatewayKeys: ['a', 'b', 'c'],
    healthByGateway: health,
    action: 'com.openclaw.v5.status',
    roleGatewayMap: {}
  });
  assert.equal(key, 'b');
});

test('failover_set falls back to active gateway if pool has no healthy target', () => {
  const key = chooseGatewayKey({
    mode: 'failover_set',
    failoverGatewayKeys: ['c', 'c'],
    activeGatewayKey: 'a',
    availableGatewayKeys: ['a', 'b', 'c'],
    healthByGateway: health,
    action: 'com.openclaw.v5.status',
    roleGatewayMap: {}
  });
  assert.equal(key, 'a');
});

test('latency_best picks lowest latency healthy gateway', () => {
  const key = chooseGatewayKey({
    mode: 'latency_best',
    activeGatewayKey: 'a',
    availableGatewayKeys: ['a', 'b', 'c'],
    healthByGateway: health,
    action: 'com.openclaw.v5.status',
    roleGatewayMap: {}
  });
  assert.equal(key, 'b');
});

test('role_based picks mapped role gateway', () => {
  const key = chooseGatewayKey({
    mode: 'role_based',
    activeGatewayKey: 'a',
    availableGatewayKeys: ['a', 'b', 'c'],
    healthByGateway: health,
    action: 'com.openclaw.v5.websearch',
    roleGatewayMap: { research: 'b', default: 'a' }
  });
  assert.equal(key, 'b');
});

test('normalizeContextRoutingSettings sanitizes to available gateways', () => {
  const out = normalizeContextRoutingSettings(
    {
      routeMode: 'failover_set',
      fixedGatewayKey: 'zzz',
      failoverGatewayKeys: 'zzz,b,b,a,a'
    },
    ['a', 'b', 'c'],
    'a'
  );
  assert.equal(out.routeMode, 'failover_set');
  assert.equal(out.fixedGatewayKey, 'a');
  assert.deepEqual(out.failoverGatewayKeys, ['b', 'a']);
});
