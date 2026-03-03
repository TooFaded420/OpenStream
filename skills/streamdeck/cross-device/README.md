# OpenClaw Cross-Device Network Setup

## 🌐 Overview
Connect your **Windows PC** and **Mac Mini** so they can:
- ✅ Monitor each other's health
- ✅ Self-heal (restart if one fails)
- ✅ Sync sessions
- ✅ Load-balance agents
- ✅ Failover automatically

---

## 📋 Prerequisites

- Both devices on same network (WiFi)
- OpenClaw installed on both
- Know both IP addresses

**Your Setup:**
- Windows PC: `192.168.1.100`
- Mac Mini: `192.168.1.50`

---

## 🚀 Quick Setup

### Step 1: Windows Setup

**On your Windows PC (Origin):**

```powershell
# Run setup script
& "$env:USERPROFILE\.openclaw\workspace\skills\streamdeck\cross-device\network-setup.ps1"
```

**Configure Windows OpenClaw:**

Edit `%USERPROFILE%\.openclaw\openclaw.json`:

```json
{
  "gateway": {
    "port": 18790,
    "bind": "lan",
    "auth": {
      "mode": "token",
      "token": "oc_gw_windows_token_YOUR_TOKEN_HERE",
      "allowUnpaired": true
    }
  }
}
```

**Allow Windows Firewall:**
```powershell
# Allow port 18790 through firewall
New-NetFirewallRule -DisplayName "OpenClaw Cross-Device" -Direction Inbound -LocalPort 18790 -Protocol TCP -Action Allow
```

**Restart OpenClaw:**
```powershell
openclaw gateway restart
```

---

### Step 2: Mac Setup

**On your Mac Mini:**

```bash
# Copy the Mac setup script
cp /path/to/mac-setup.sh ~/mac-setup.sh

# Make executable
chmod +x ~/mac-setup.sh

# Run setup
~/mac-setup.sh
```

**Configure Mac OpenClaw:**

Edit `~/.openclaw/openclaw.json`:

```json
{
  "gateway": {
    "port": 18790,
    "bind": "lan",
    "auth": {
      "mode": "token",
      "token": "oc_gw_mac_token_YOUR_TOKEN_HERE",
      "allowUnpaired": true
    }
  }
}
```

**Allow Mac Firewall:**
```bash
# Allow OpenClaw through firewall
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --add /usr/local/bin/openclaw
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --unblockapp /usr/local/bin/openclaw
```

**Restart OpenClaw:**
```bash
openclaw gateway restart
```

---

### Step 3: Test Connection

**From Windows, test Mac:**
```powershell
# Test Mac connection
Invoke-RestMethod -Uri "http://192.168.1.50:18790/status" -Method Get
```

**From Mac, test Windows:**
```bash
# Test Windows connection
curl http://192.168.1.100:18790/status
```

**Both should return status JSON.** ✅

---

## 🤖 Enable Self-Healing

### Windows (Auto-monitor Mac):
```powershell
# Start self-healing (runs in background)
Start-Job -ScriptBlock { 
    & "$env:USERPROFILE\.openclaw\workspace\skills\streamdeck\cross-device\network-setup.ps1"
    Start-SelfHealing 
}
```

### Mac (Auto-monitor Windows):
```bash
# Start self-healing
~/mac-setup.sh start_self_healing
```

---

## 📊 What Self-Healing Does

Every 30 seconds:
1. ✅ Checks if both OpenClaw instances are healthy
2. 🔧 If Windows fails → Mac tries to restart it
3. 🔧 If Mac fails → Windows tries to restart it
4. 🔄 Syncs sessions between devices
5. 📊 Reports status to your Telegram

---

## 🎯 Use Cases

### 1. Agent Load Balancing
Spawn agents on least-loaded device:
```powershell
Distribute-AgentTask -Task "Analyze code" -Parameters @{ file = "main.py" }
# Automatically chooses Windows or Mac
```

### 2. Cross-Device Session Sync
Work on PC → Continue on Mac seamlessly.

### 3. Automatic Failover
If PC crashes → Mac takes over all sessions.

### 4. Parallel Processing
Split large tasks across both devices.

---

## 🔧 Troubleshooting

### "Connection refused"
- Check firewall rules
- Verify OpenClaw is running on both
- Check IP addresses are correct

### "Token mismatch"
- Copy tokens between configs
- Restart both gateways

### "Health check fails"
- Verify network connectivity: `ping 192.168.1.50` (from Windows)
- Check OpenClaw logs

---

## 📁 Files Created

| File | Purpose |
|------|---------|
| `cross-device/network-setup.ps1` | Windows setup & self-healing |
| `cross-device/mac-setup.sh` | Mac setup & self-healing |
| `~/.openclaw/cross-device-config.json` | Shared config |

---

## 🎉 Next Steps

1. ✅ Setup complete
2. ✅ Test connections
3. ✅ Enable self-healing
4. ✅ Start using cross-device features

**Your devices can now self-heal and work together!** 🦞
