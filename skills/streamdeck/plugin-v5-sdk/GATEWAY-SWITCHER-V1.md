# Gateway Switcher v1 Documentation

Switch between multiple OpenClaw gateways from your Stream Deck. Supports local instances, remote machines via Tailscale, and mobile devices.

---

## Table of Contents

- [Configuration Schema](#configuration-schema)
- [Usage Examples](#usage-examples)
- [Key Action Guide](#key-action-guide)
- [Dial Action Guide](#dial-action-guide)
- [Troubleshooting](#troubleshooting)
- [Validation Checklist](#validation-checklist)

---

## Configuration Schema

### Gateway Config JSON Schema

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "title": "Gateway Switcher Configuration",
  "description": "Configure multiple OpenClaw gateway endpoints",
  "properties": {
    "primary": {
      "type": "string",
      "format": "uri",
      "description": "Primary gateway URL (default/local)",
      "example": "http://127.0.0.1:18790"
    },
    "secondary": {
      "type": "string",
      "format": "uri",
      "description": "Secondary gateway URL (remote/Tailscale)",
      "example": "http://100.92.222.41:18789"
    },
    "phone": {
      "type": "string",
      "format": "uri",
      "description": "Mobile device gateway via Tailscale",
      "example": "http://100.x.x.x:18790"
    },
    "work": {
      "type": "string",
      "format": "uri",
      "description": "Work/Office gateway"
    },
    "home": {
      "type": "string",
      "format": "uri",
      "description": "Home server gateway"
    }
  },
  "required": ["primary"],
  "additionalProperties": {
    "type": "string",
    "format": "uri"
  }
}
```

### Stream Deck Action Settings Schema

```json
{
  "type": "object",
  "properties": {
    "action": {
      "type": "string",
      "enum": ["gateway-switch"],
      "description": "Must be 'gateway-switch' for switcher functionality"
    },
    "gatewayKey": {
      "type": "string",
      "description": "Current active gateway key (matches config keys)",
      "example": "primary"
    },
    "gateways": {
      "type": "object",
      "description": "Gateway endpoints map",
      "additionalProperties": {
        "type": "string",
        "format": "uri"
      }
    },
    "timeoutMs": {
      "type": "integer",
      "minimum": 1000,
      "maximum": 30000,
      "default": 9000,
      "description": "Connection timeout in milliseconds"
    }
  },
  "required": ["action", "gateways"]
}
```

### Config File Location

| Platform | Path |
|----------|------|
| Windows | `%USERPROFILE%\.openclaw\streamdeck-plugin\gateway-config.json` |
| macOS | `~/.openclaw/streamdeck-plugin/gateway-config.json` |
| Linux | `~/.openclaw/streamdeck-plugin/gateway-config.json` |

---

## Usage Examples

### Example 1: Dual Local Ports (Development)

For running multiple OpenClaw instances on different ports:

```json
{
  "primary": "http://127.0.0.1:18790",
  "secondary": "http://127.0.0.1:18791"
}
```

**Use Case:** Testing different OpenClaw versions or configurations locally.

**Setup:**
```powershell
# Instance 1 (primary)
openclaw config set gateway.port 18790
openclaw gateway start

# Instance 2 (secondary)  
openclaw config set gateway.port 18791
openclaw gateway start
```

---

### Example 2: Local + Mac Mini via Tailscale

Windows PC + Mac Mini on same Tailscale network:

```json
{
  "primary": "http://127.0.0.1:18790",
  "secondary": "http://100.92.222.41:18789"
}
```

**Use Case:** Switch between Windows workstation and Mac Mini for different workloads.

**Setup:**
1. Install Tailscale on both machines
2. Find Mac's Tailscale IP: `tailscale status`
3. Start OpenClaw on Mac: `openclaw gateway start`
4. Verify connection: `ping 100.92.222.41`

---

### Example 3: Local + Phone + Tailscale Node

Full multi-device setup:

```json
{
  "primary": "http://127.0.0.1:18790",
  "phone": "http://100.71.123.45:18790",
  "tailscale": "http://100.92.222.41:18789"
}
```

**Use Case:** Control OpenClaw from phone while away, or switch to home server.

**Phone Gateway Setup:**
```bash
# On Android (Termux)
pkg install nodejs
npm install -g openclaw
openclaw gateway start --port 18790

# Get Tailscale IP
tailscale ip -4
```

---

### Example 4: Complete Multi-Environment

Enterprise/home lab setup:

```json
{
  "primary": "http://127.0.0.1:18790",
  "secondary": "http://192.168.1.10:18790",
  "work": "http://10.0.0.5:18790",
  "phone": "http://100.71.123.45:18790",
  "cloud": "https://openclaw.myserver.com"
}
```

---

## Key Action Guide

### Button Configuration

**Step 1:** Create switch button in Stream Deck software:

1. Drag "OpenClaw Action" to a button
2. Configure settings:

```json
{
  "action": "gateway-switch",
  "gatewayKey": "primary",
  "gateways": {
    "primary": "http://127.0.0.1:18790",
    "secondary": "http://100.92.222.41:18789"
  },
  "timeoutMs": 9000
}
```

**Step 2:** Set visual feedback:

| State | Display | Meaning |
|-------|---------|---------|
| `G:primary` | Green text | Connected to primary |
| `G:secondary` | Orange text | Connected to secondary |
| `✓` | Green check | Gateway online |
| `✗` | Red X | Gateway offline |
| `TIME` | Amber | Connection timeout |
| `AUTH` | Red | Authentication failed |

---

### Key Action Workflow

```
┌─────────────────────────────────────────┐
│  Press Gateway Switch Button            │
│     ↓                                   │
│  Test Current Gateway                   │
│     ↓                                   │
│  Offline? → Try Next Gateway → Connect  │
│     ↓                                   │
│  Update All Button States               │
│     ↓                                   │
│  Show "G:<key>" on Switch Button        │
└─────────────────────────────────────────┘
```

---

## Dial Action Guide

### Stream Deck Plus / Neo Dial Integration

Gateway Switcher works with Dial Pack v1 for rotary control.

**Dial Action Configuration:**

```json
{
  "UUID": "com.openclaw.v5.dial.gateway",
  "Name": "Dial: Gateway Switch",
  "Tooltip": "Rotate: cycle gateways | Press: test connection",
  "Icon": "images/nodes",
  "Controllers": ["Encoder"],
  "SupportedDevices": ["Stream Deck +", "Stream Deck Neo"],
  "Encoder": {
    "layout": "$A1",
    "Icon": "images/nodes",
    "Title": "Gateway"
  }
}
```

### Dial Behaviors

| Gesture | Action | Result |
|---------|--------|--------|
| **Rotate CW** | Next gateway | Cycle: primary → secondary → phone → ... |
| **Rotate CCW** | Previous gateway | Cycle backwards |
| **Press** | Test connection | Ping gateway, show latency |
| **Hold + Rotate** | Quick switch | Jump 2 gateways at a time |

### Dial Touch Strip Display

```
┌────────────────────────────────┐
│  Gateway                       │  ← Title
│  primary                       │  ← Current gateway key
│  [==========>      ] 45ms      │  ← Latency indicator
└────────────────────────────────┘
```

**Touch Strip Zones:**

| Zone | Action |
|------|--------|
| Left 1/3 | Jump to primary |
| Center 1/3 | Test current |
| Right 1/3 | Next gateway |

### Dial Event Handling

```javascript
// Handle dial rotation for gateway switching
async function handleGatewayDial(evt) {
  const { context, payload } = evt;
  const { ticks } = payload || {};
  
  const gatewayKeys = Object.keys(cfg.gateways);
  const len = gatewayKeys.length;
  
  if (ticks) {
    // Cycle through gateways
    currentGatewayIndex = ((currentGatewayIndex + ticks) % len + len) % len;
    const key = gatewayKeys[currentGatewayIndex];
    
    // Update display
    setFeedback(context, { 
      title: 'Gateway', 
      value: key,
      indicator: { value: currentGatewayIndex, range: { min: 0, max: len - 1 } }
    });
  }
}

// Handle dial press - test connection
async function handleGatewayDialPress(evt) {
  const { context } = evt;
  const key = gatewayKeys[currentGatewayIndex];
  const url = cfg.gateways[key];
  
  setFeedback(context, { title: 'Testing...', value: key });
  
  const res = await testGateway(url);
  const status = res.ok ? `${res.latencyMs}ms` : 'OFF';
  
  setFeedback(context, { title: key, value: status });
}
```

---

## Troubleshooting

### Authentication Errors (AUTH)

**Symptom:** Button shows `AUTH` or `401/403`

**Causes & Fixes:**

| Cause | Check | Fix |
|-------|-------|-----|
| Missing API key | `openclaw config get gateway.apiKey` | Set key: `openclaw config set gateway.apiKey <key>` |
| Key mismatch | Compare keys on both gateways | Sync keys or use same config |
| CORS blocked | Browser console errors | Add origin to allowed hosts |
| Token expired | Session timeout | Regenerate: `openclaw auth refresh` |

**Debug authentication:**
```powershell
# Test with explicit auth
$headers = @{ "Authorization" = "Bearer $apiKey" }
Invoke-RestMethod -Uri "http://100.92.222.41:18789/status" -Headers $headers
```

---

### Timeout Issues (TIME)

**Symptom:** Button shows `TIME` or `OFF`

**Network Diagnostics:**

```powershell
# 1. Check Tailscale connectivity
tailscale status
tailscale ping 100.92.222.41

# 2. Test direct connection
Test-NetConnection -ComputerName 100.92.222.41 -Port 18789

# 3. Check gateway status remotely
ssh user@100.92.222.41 "openclaw gateway status"

# 4. Verify firewall
# Windows: Check Defender rules
# macOS: Check Application Firewall
# Linux: Check iptables/ufw
```

**Timeout Configuration:**

```json
{
  "action": "gateway-switch",
  "timeoutMs": 15000,
  "gateways": { ... }
}
```

| Scenario | Recommended Timeout |
|----------|---------------------|
| Local only | 3000ms |
| Local + Tailscale | 9000ms |
| Mobile/High latency | 15000ms |
| Cloud/Internet | 20000ms |

---

### Connection Refused

**Symptom:** `ERR` or `Connection refused`

**Checklist:**

- [ ] Gateway running on target machine: `openclaw gateway status`
- [ ] Correct port in URL (18790 vs 18789)
- [ ] Firewall allowing connection
- [ ] Tailscale connected on both ends
- [ ] No VPN conflicts

**Quick fix:**
```powershell
# Restart target gateway
ssh user@100.92.222.41 "openclaw gateway restart"

# Or locally
openclaw gateway restart
```

---

### Dial Not Switching

**Symptom:** Dial rotates but gateway doesn't change

**Fixes:**

1. **Verify dial event received:**
```javascript
// Add debug logging
ws.addEventListener('message', (event) => {
  console.log('[RAW]', event.data);
});
```

2. **Check controller type:**
```javascript
if (payload?.controller !== 'Encoder') {
  console.warn('Not an encoder event');
  return;
}
```

3. **Reset dial state:**
```javascript
// Force reset
send({ event: 'setFeedbackLayout', context, payload: { layout: '$A1' } });
```

---

### Common Error Codes

| Code | Meaning | Resolution |
|------|---------|------------|
| `OK` | Success | Working correctly |
| `OFF` | Gateway offline | Start gateway, check network |
| `TIME` | Timeout | Increase timeout, check latency |
| `AUTH` | Auth failed | Verify API key, check permissions |
| `NF` | 404 Not Found | Wrong endpoint, check URL |
| `ERR` | General error | Check logs, restart plugin |

---

## Validation Checklist

### Pre-Flight Checks

Before using Gateway Switcher, verify:

- [ ] All target gateways installed and running
- [ ] Network connectivity between devices (ping/Tailscale)
- [ ] Stream Deck plugin v5.2.0+ installed
- [ ] Configuration file exists and is valid JSON
- [ ] At least one gateway responding at `/status`

### Functional Tests

**Test 1: Primary Gateway**
```powershell
Invoke-RestMethod -Uri "http://127.0.0.1:18790/status"
# Expected: JSON with status: "ok"
```

**Test 2: Secondary Gateway**
```powershell
Invoke-RestMethod -Uri "http://100.92.222.41:18789/status"
# Expected: JSON with status: "ok"
```

**Test 3: Switch Function**
1. Press Gateway Switch button
2. Verify button text changes to `G:secondary`
3. Press TTS button - should use secondary gateway
4. Switch back - verify `G:primary` appears

**Test 4: Dial Integration (SD Plus/Neo)**
1. Rotate dial - should cycle through gateways
2. Press dial - should show latency
3. Touch strip should display current gateway

### Performance Benchmarks

| Metric | Target | Acceptable |
|--------|--------|------------|
| Local latency | <10ms | <50ms |
| Tailscale latency | <50ms | <150ms |
| Switch time | <2s | <5s |
| Dial response | <100ms | <300ms |

### Log Verification

Check logs for successful operation:

```powershell
# Stream Deck plugin logs
Get-Content "$env:TEMP\openclaw-v5-runtime.log" -Tail 50

# Look for:
# [openclaw-v5] api GET /status
# [openclaw-v5] gateway switch: primary -> secondary
```

### Final Sign-Off

- [ ] All gateways accessible
- [ ] Switch button working
- [ ] Visual feedback correct
- [ ] Dial actions responsive (if applicable)
- [ ] No errors in logs
- [ ] Ready for production use

---

## Quick Reference Card

```
┌──────────────────────────────────────────────────────┐
│              GATEWAY SWITCHER v1                     │
├──────────────────────────────────────────────────────┤
│ Config: ~/.openclaw/streamdeck-plugin/               │
│         gateway-config.json                          │
├──────────────────────────────────────────────────────┤
│ KEY ACTION:                                          │
│   Press → Switch to next available gateway          │
│                                                      │
│ DIAL ACTION (SD Plus/Neo):                          │
│   Rotate → Cycle gateways                           │
│   Press  → Test connection                          │
├──────────────────────────────────────────────────────┤
│ DISPLAY CODES:                                       │
│   G:<key> = Current gateway                         │
│   ✓      = Online                                   │
│   ✗      = Offline                                  │
│   TIME   = Timeout                                  │
│   AUTH   = Auth failed                              │
├──────────────────────────────────────────────────────┤
│ QUICK FIXES:                                         │
│   OFF  → openclaw gateway start                     │
│   TIME → Check Tailscale/network                    │
│   AUTH → Verify API key                             │
└──────────────────────────────────────────────────────┘
```

---

## Related Documentation

- [Multi-Gateway Guide](../../MULTI-GATEWAY-GUIDE.md) - Full multi-gateway setup
- [Dial Pack v1](./DIAL-PACK-V1.md) - Stream Deck Plus dial actions
- [Profile Layout](./PROFILE-LAYOUT.md) - Button assignments
- [Troubleshooting Guide](../../TROUBLESHOOT-GUIDE.md) - General fixes

---

*Gateway Switcher v1 - Compatible with OpenClaw Stream Deck SDK v5.2.0+*