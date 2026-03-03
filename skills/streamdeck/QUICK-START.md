# Quick Start: Get OpenClaw on Your Stream Decks

**Your Hardware:** MK.2 + Plus  
**Time:** 5 minutes  
**Goal:** Control OpenClaw from Stream Deck buttons

---

## 🚀 Installation (3 Steps)

### Step 1: Configure Multi-Gateway

Sets up switching between Origin and Mac Mini:

```powershell
cd "$env:USERPROFILE\.openclaw\workspace\skills\streamdeck"
.\MULTI-GATEWAY-CONFIG.ps1
```

**What this does:**
- Saves your gateway URLs
- Primary: `http://127.0.0.1:18790` (Origin)
- Secondary: `http://100.92.222.41:18789` (Mac)

### Step 2: Install Profiles

Generates and imports button layouts:

```powershell
.\INSTALL-PROFILES.ps1
```

**What this creates:**
- `OpenClaw-Control-MK2` (15 buttons)
- `OpenClaw-Studio-Plus` (15 buttons + 4 dials)

### Step 3: Restart Stream Deck

1. Right-click Stream Deck icon in system tray
2. Click "Quit"
3. Reopen Stream Deck
4. Wait 10 seconds for plugins to load

---

## 🎮 Using Your Buttons

### MK.2 Layout (Left Hand)

```
┌────────┬────────┬────────┬────────┬────────┐
│ Switch │  TTS   │ Spawn  │ Status │ Models │  ← Row 1
│   GW   │ Toggle │ Agent  │ Check  │  List  │
├────────┼────────┼────────┼────────┼────────┤
│ Nodes  │Restart │ Config │ Session│ Memory │  ← Row 2
├────────┼────────┼────────┼────────┼────────┤
│ Search │ Code   │ Debug  │ Message│ Browser│  ← Row 3
└────────┴────────┴────────┴────────┴────────┘
```

**Key buttons:**
- **Switch GW** (top-left): Toggle between Origin ↔ Mac Mini
- **Spawn Agent**: Quick AI agent spawn
- **Status**: Check OpenClaw health
- **TTS Toggle**: Enable/disable voice

### Plus Layout (Right Hand)

**Keys:** Similar to MK.2

**Dials:**
- **Dial 1**: System volume (press = mute)
- **Dial 2**: Mic volume (press = push-to-talk)
- **Dial 3**: Brightness (press = reset)
- **Dial 4**: Scroll (press = jump to top)

---

## 🔄 Switching Gateways

**To switch from Origin to Mac Mini:**

1. Press **"Switch GW"** button
2. Button shows **"G:secondary"**
3. All other buttons now use **Mac Mini** gateway!
4. Spawn agent → Runs on Mac
5. Press again → Back to Origin

**Visual feedback:**
- Green check = Gateway online
- Red X = Gateway offline
- Text shows which gateway is active

---

## 🧪 Testing

**Test 1: Gateway Switch**
1. Press "Switch GW" on MK.2
2. Should show "G:secondary"
3. Press "Status"
4. Should show Mac Mini status

**Test 2: Spawn Agent**
1. Make sure you're on desired gateway
2. Press "Spawn Agent"
3. Check OpenClaw - new agent should appear!

**Test 3: Dial Control**
1. Turn Dial 1 (Plus)
2. System volume should change
3. Press dial = mute toggle

---

## 🎨 Customization

### Change Button Icons

1. Right-click button in Stream Deck software
2. "Set from File"
3. Choose from `assets/icons/`

### Move Buttons

Just drag and drop in Stream Deck software

### Add Custom Actions

Edit `BUTTON-LAYOUTS.json` and re-run `INSTALL-PROFILES.ps1`

---

## ❌ Troubleshooting

### "No gateway available"

**Cause:** Both gateways offline

**Fix:**
```powershell
# Check Origin
openclaw gateway status

# Check Mac (SSH)
ssh user@100.92.222.41
openclaw gateway status
```

### Buttons not responding

**Check:**
1. Is Stream Deck software running?
2. Is OpenClaw gateway running?
3. Try restarting Stream Deck

### Wrong gateway

**Fix:** Press "Switch GW" to toggle

---

## 📞 Need Help?

- Check full guide: `MULTI-GATEWAY-GUIDE.md`
- Detection report: `streamdeck-report.json`
- Button layouts: `BUTTON-LAYOUTS.json`

**Enjoy your Stream Deck + OpenClaw setup!** 🎮