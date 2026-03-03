---
name: streamdeck-auto
description: Automatically set up and configure OpenClaw integration with Elgato Stream Deck hardware. Use when user mentions Stream Deck, wants to control OpenClaw from Stream Deck, asks about Stream Deck buttons/actions, or wants physical buttons for AI control. Provides one-click installation, auto-detection of hardware, multi-gateway support, and pre-configured layouts for MK.2, Plus, and XL models.
---

# Stream Deck Auto-Setup Skill

One-command automatic setup for Stream Deck + OpenClaw integration.

## When This Skill Triggers

- User mentions "Stream Deck"
- User wants physical buttons for AI control
- User asks about controlling OpenClaw from hardware
- User wants to set up Elgato Stream Deck
- "I want buttons to spawn agents"
- "Can I use Stream Deck with OpenClaw?"

## What This Skill Does

1. **Auto-detects** your Stream Deck hardware (MK.2, Plus, XL, Mini)
2. **Installs** OpenClaw plugin automatically
3. **Generates** optimized button layouts for your specific devices
4. **Configures** multi-gateway switching (if you have multiple gateways)
5. **Imports** everything to Stream Deck software
6. **Tests** the connection to ensure it works

## One-Command Setup

Run this single command and everything is done:

```powershell
openclaw skills run streamdeck-auto
```

Or manually:
```powershell
."$env:USERPROFILE/.openclaw/skills/streamdeck-auto/SETUP.ps1"
```

## What Happens Automatically

### Step 1: Detection (10 seconds)
- Scans USB for connected Stream Decks
- Identifies models (MK.2, Plus, XL, Mini)
- Checks Stream Deck software installation

### Step 2: Installation (30 seconds)
- Installs OpenClaw plugin for Stream Deck
- Downloads essential plugins (BarRaider, etc.)
- Generates custom profiles for your hardware

### Step 3: Configuration (10 seconds)
- Detects your OpenClaw gateways
- Sets up multi-gateway switching
- Configures button actions

### Step 4: Import (5 seconds)
- Imports profiles to Stream Deck software
- Restarts Stream Deck to load everything
- Tests connection

**Total time: ~1 minute**

## After Setup

Your Stream Deck will have buttons for:

| Button | Action |
|--------|--------|
| 🤖 Spawn Agent | Spawn AI agent |
| 🎤 TTS Toggle | Enable/disable voice |
| 📊 Status Check | View OpenClaw status |
| 🧠 Models | List/switch AI models |
| ⚡ Subagents | View active agents |
| 🔄 Switch GW | Toggle between gateways |
| 💻 Code | Spawn coding agent |
| 🔍 Search | Web search |
| 📝 Memory | Search memory |
| 🌐 Browser | Open browser control |

## Multi-Gateway Support

If you have multiple OpenClaw instances (e.g., Origin + Mac Mini):

1. Setup detects all gateways automatically
2. "Switch GW" button toggles between them
3. All buttons use the selected gateway
4. Visual indicator shows which is active

## Supported Hardware

- ✅ Stream Deck Mini (6 keys)
- ✅ Stream Deck MK.2 (15 keys)
- ✅ Stream Deck Plus (15 keys + 4 dials)
- ✅ Stream Deck XL (32 keys)
- ✅ Stream Deck Pedal (3 pedals)

## Customization

After auto-setup, customize via Stream Deck software:
- Drag to rearrange buttons
- Change icons
- Add custom actions
- Create multiple profiles

## Troubleshooting

If setup fails, run:
```powershell
openclaw skills run streamdeck-auto -Diagnostics
```

Common fixes:
- Ensure Stream Deck software is installed
- Check USB connection
- Run PowerShell as Administrator

## Files This Skill Creates

- Stream Deck plugin: `%APPDATA%/Elgato/StreamDeck/Plugins/`
- Profiles: `%APPDATA%/Elgato/StreamDeck/ProfilesV2/`
- Config: `~/.openclaw/streamdeck-config.json`

## Updates

To update to latest version:
```powershell
openclaw skills update streamdeck-auto
```

## Uninstall

To remove:
```powershell
openclaw skills run streamdeck-auto -Uninstall
```

---

**This skill provides turnkey Stream Deck integration for OpenClaw.**