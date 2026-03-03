# My Stream Deck Setup

**Hardware:** MK.2 + Plus (2 decks)

---

## 🎮 Stream Deck MK.2 (15 keys)

**Profile:** "OpenClaw Control MK2"

### Layout

```
┌────────┬────────┬────────┬────────┬────────┐
│ Switch │  TTS   │ Spawn  │ Status │ Models │
│   GW   │ Toggle │ Agent  │ Check  │  List  │
├────────┼────────┼────────┼────────┼────────┤
│ Nodes  │Restart │ Config │ Session│ Memory │
├────────┼────────┼────────┼────────┼────────┤
│ Search │ Code   │ Debug  │ Message│ Browser│
└────────┴────────┴────────┴────────┴────────┘
```

### Button Details

| Key | Action | Purpose |
|-----|--------|---------|
| 1 | **Switch GW** | Toggle Origin ↔ Mac Mini |
| 2 | **TTS Toggle** | Enable/disable voice |
| 3 | **Spawn Agent** | Quick AI agent |
| 4 | **Status Check** | OpenClaw health |
| 5 | **Models** | List available models |
| 6 | **Nodes** | Check paired devices |
| 7 | **Restart** | Restart gateway |
| 8 | **Config** | View settings |
| 9 | **Session** | Current session info |
| 10 | **Memory** | Search memory |
| 11 | **Search** | Web search |
| 12 | **Code** | Spawn coding agent |
| 13 | **Debug** | Debug help |
| 14 | **Message** | Send Telegram message |
| 15 | **Browser** | Open browser control |

---

## 🎛️ Stream Deck Plus (15 keys + 4 dials)

**Profile:** "OpenClaw Studio Plus"

### Keys Layout

```
┌────────┬────────┬────────┬────────┬────────┐
│ Switch │ Spawn  │ Status │ Models │ Session│
│   GW   │ Agent  │ Check  │  List  │  Info  │
├────────┼────────┼────────┼────────┼────────┤
│ TTS    │Restart │ Config │ Memory │ Search │
├────────┼────────┼────────┼────────┼────────┤
│ Nodes  │ Code   │ Debug  │ Message│ Browser│
└────────┴────────┴────────┴────────┴────────┘
```

### Dial Functions

| Dial | Turn | Press |
|------|------|-------|
| **1** | System Volume | Mute toggle |
| **2** | Mic Volume | Push to talk |
| **3** | Brightness | Reset default |
| **4** | Scroll/Jog | Jump to top |

---

## 🚀 Installation Steps

### Step 1: Run Config
```powershell
cd "$env:USERPROFILE\.openclaw\workspace\skills\streamdeck"
.\MULTI-GATEWAY-CONFIG.ps1
```

### Step 2: Install Plugin
```powershell
.\INSTALLER.ps1
```

### Step 3: Import Profiles

**MK.2:**
1. Stream Deck software → Import
2. Select: `OpenClaw-Control-MK2.sdProfile`

**Plus:**
1. Stream Deck software → Import
2. Select: `OpenClaw-Studio-Plus.sdProfile`

### Step 4: Test
1. Press **Switch GW** on MK.2
2. Verify shows "G:secondary" (Mac)
3. Press **Spawn Agent**
4. Check it spawns on Mac!

---

## 🎯 Quick Actions

**MK.2 (Left hand):**
- Top row: Gateway switching + AI control
- Middle: System tools
- Bottom: Coding + communication

**Plus (Right hand):**
- Keys: Similar to MK.2 but optimized for dials
- Dials: Media control + navigation

---

## 💡 Pro Tips

- **Color code:** Blue = AI, Green = System, Orange = Tools
- **Switch GW** is your most important button - use it often!
- **Plus dials** are great for volume while working
- **MK.2** is perfect for quick AI tasks

Ready to install on your decks? 🎮