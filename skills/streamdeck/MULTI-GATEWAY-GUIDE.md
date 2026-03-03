# Multi-Gateway Setup Guide

Switch between multiple OpenClaw gateways (Origin + Mac Mini) from your Stream Deck.

## 🎯 Your Setup

| Gateway | Device | URL | Status |
|---------|--------|-----|--------|
| **Primary** | Origin (Windows) | `http://127.0.0.1:18790` | ✅ Local |
| **Secondary** | Mac Mini | `http://100.92.222.41:18789` | ✅ Via Tailscale |

## 🚀 Quick Setup

### Step 1: Configure Gateways

Run the configuration script:

```powershell
.\MULTI-GATEWAY-CONFIG.ps1
```

This saves your gateway URLs to:
`%USERPROFILE%\.openclaw\streamdeck-plugin\gateway-config.json`

### Step 2: Create Switch Button

1. Open Stream Deck software
2. Drag "OpenClaw Action" to a button
3. Configure:
   - **Action:** `gateway-switch`
   - **Icon:** Use `switch-gateway.png` (or any icon)
   - **Title:** "Switch GW"

### Step 3: Test

1. Press the button
2. Watch the button text change:
   - "G:primary" = Using Origin
   - "G:secondary" = Using Mac Mini
3. Try other buttons - they now use the selected gateway!

## 🎮 How It Works

### Button States

| State | Display | Meaning |
|-------|---------|---------|
| ✓ | Green | Gateway online |
| ✗ | Red | Gateway offline |
| G:primary | Label | Using Origin |
| G:secondary | Label | Using Mac Mini |

### Switching Logic

```
Current: Primary (Origin)
    ↓
Press "Switch Gateway"
    ↓
Test Secondary (Mac)
    ↓
If online → Switch to Mac
If offline → Stay on Origin
```

## 🔄 Usage Examples

### Scenario 1: Switch to Mac for Remote Work

```
[Working on Origin]
    ↓
[Press "Switch Gateway"]
    ↓
[Now using Mac Mini gateway]
    ↓
[Spawn agent on Mac]
    ↓
[Check Mac node cameras]
    ↓
[Press again to switch back]
```

### Scenario 2: Auto-Switch on Failover

If Origin gateway goes down, Stream Deck can auto-switch to Mac:

1. Status shows "✗" on Origin
2. Press Switch Gateway
3. Automatically tests Mac
4. Switches if Mac is online

## 🛠️ Advanced Configuration

### Custom Gateways

Edit `gateway-config.json`:

```json
{
  "primary": "http://127.0.0.1:18790",
  "secondary": "http://100.92.222.41:18789",
  "work": "http://work-server:18790",
  "home": "http://192.168.1.50:18790"
}
```

### Per-Button Gateway

Some buttons can use specific gateways:

```json
{
  "action": "spawn",
  "gatewayKey": "secondary",
  "settings": { "task": "Mac-specific task" }
}
```

### Visual Indicators

Add multiple status buttons:

- **Button 1:** Origin status (always shows primary)
- **Button 2:** Mac status (always shows secondary)
- **Button 3:** Switch between them

## 🔍 Troubleshooting

### "No gateway available"

**Cause:** Both gateways offline

**Fix:**
```powershell
# Check Origin
openclaw gateway status

# Check Mac (SSH in)
ssh user@100.92.222.41
openclaw gateway status
```

### Can't reach Mac

**Cause:** Tailscale not connected

**Fix:**
1. Check Tailscale on both machines
2. Verify IPs: `tailscale status`
3. Test: `ping 100.92.222.41`

### Button not switching

**Cause:** Config not loaded

**Fix:**
```powershell
# Restart Stream Deck
# Or reload plugin
```

## 📊 Network Diagram

```
┌─────────────────┐         ┌─────────────────┐
│   Stream Deck   │◄───────►│   Origin (Win)  │
│     Hardware    │  USB    │  127.0.0.1:18790│
└────────┬────────┘         └─────────────────┘
         │
         │ Network
         │
         ▼
┌─────────────────┐
│   Mac Mini      │
│100.92.222.41:18789│
│  (Tailscale)    │
└─────────────────┘
```

## 🎨 Button Layout Suggestion

**Row 1: Gateway Control**
```
┌─────────┬─────────┬─────────┐
│ Origin  │ Switch  │  Mac    │
│ Status  │ Gateway │ Status  │
└─────────┴─────────┴─────────┘
```

**Row 2-3: Actions (use selected gateway)**
```
[TTS] [Spawn] [Status] [Models] [Subagents]
[Node] [Restart] [Config] [Session] [Search]
```

## 💡 Tips

1. **Color-code buttons:** Blue for Origin, Orange for Mac
2. **Use different profiles:** One for Origin-focused work, one for Mac
3. **Auto-switch:** Use BarRaider to auto-switch based on time/network
4. **Backup:** Keep both gateways running for redundancy

## 🔗 Related Files

- `plugin-v3/openclaw-plugin-v3.ps1` - Main plugin code
- `MULTI-GATEWAY-CONFIG.ps1` - Configuration script
- `GATEWAY-SWITCH-BUTTON.json` - Button template

---

**Ready to switch?** Configure and test now! 🚀