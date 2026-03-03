---
name: streamdeck
description: Control OpenClaw from Elgato Stream Deck hardware. Use when user wants to set up Stream Deck integration, configure Stream Deck buttons for OpenClaw, detect Stream Deck devices, install plugins, generate profiles, or troubleshoot Stream Deck connectivity. Supports Mini, MK.2, Plus, XL, and Pedal models.
---

# Stream Deck + OpenClaw Integration

Control your OpenClaw AI assistant directly from Stream Deck hardware buttons.

## Quick Start (One Command)

Run automatic setup to detect hardware, install plugins, and generate profiles:

```powershell
."scripts/auto-setup-v3.ps1"
```

This detects your Stream Decks, installs essential plugins, and creates ready-to-import profiles.

## Manual Setup

### Step 1: Detect Hardware

Identify connected Stream Decks:

```powershell
."scripts/detect-decks.ps1"
```

Creates `streamdeck-report.json` with device inventory.

### Step 2: Install Plugins

Install required plugins:

```powershell
."scripts/install-plugins.ps1"
```

**Plugins:** BarRaider Windows Utils, Stream Deck Tools, Audio Meter, CPU, OpenClaw Webhooks

### Step 3: Generate Profiles

Create OpenClaw profiles:

```powershell
."scripts/generate-profiles.ps1"
```

Generates profiles in `~/.openclaw/streamdeck-profiles/`

### Step 4: Import to Stream Deck

1. Open Stream Deck software
2. Profile dropdown → "Import Profile"
3. Navigate to `~/.openclaw/streamdeck-profiles/`
4. Select `.sdProfile` folder

## Button Actions

### AI Control
- **🔊 TTS Toggle** — Enable/disable text-to-speech
- **🤖 Spawn Agent** — Spawn sub-agent for tasks
- **📊 Status** — Check OpenClaw status
- **🧠 Models** — List available models
- **🔄 Restart** — Restart gateway
- **🔍 Search** — Web search

### System Tools
- **📡 Nodes** — Check paired nodes
- **💬 Session** — Show session info
- **⚡ Subagents** — List active agents
- **🌐 Browser** — Open browser control

## Customization

### Create Custom Buttons

1. Drag "Open System" action to button
2. Set executable: `powershell.exe`
3. Arguments: `-Command "& ~/.openclaw/skills/streamdeck/scripts/your-script.ps1"`

See [CUSTOMIZATION.md](references/CUSTOMIZATION.md) for advanced options.

### Custom Icons

Custom icons in `assets/icons/` (72×72 PNG). To use:
1. Right-click button → "Set from File"
2. Select from `assets/icons/`

## Profiles Included

| Profile | Device | Keys | Features |
|---------|--------|------|----------|
| Control | MK.2 | 15 | Essential AI functions |
| Command Center | XL | 32 | Full control + quick actions |
| Studio | Plus | 15+4dials | Content creator focused |

## Troubleshooting

### Buttons Not Responding

1. Check gateway: `openclaw gateway status`
2. Verify URL in `plugin/webhooks.ps1`
3. Test: `Invoke-RestMethod -Uri "http://127.0.0.1:18790/status"`

### Profile Not Importing

1. Update Stream Deck software
2. Check JSON syntax
3. Manual copy to `%APPDATA%/Elgato/StreamDeck/ProfilesV2/`

### Plugin Not Showing

1. Restart Stream Deck software
2. Check plugin folder: `%APPDATA%/Elgato/StreamDeck/Plugins/`
3. Re-run with admin: `scripts/install-plugins.ps1`

## Advanced Usage

See [references/ADVANCED.md](references/ADVANCED.md) for:
- Custom scripts
- Profile switching automation
- Conditional buttons
- Building custom plugins

## Command Center v1.1 - Mission Queue

Track and manage tasks with the built-in Mission Queue dashboard.

### Features
- **Three columns:** Backlog, Running, Done
- **Drag & drop** to move missions between columns
- **Priority levels:** Low, Normal, High
- **Quick add** from dashboard or Stream Deck
- **Auto-refresh** every 5 seconds

### Web Dashboard

Start the dashboard server:
```powershell
."web-dashboard/START-SERVER.bat"
```

Open browser to `http://localhost:8787` for the Command Center with Mission Queue.

### API Endpoints (Dashboard)

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/missions` | GET | List all missions (opt: `?status=backlog/running/done`) |
| `/api/missions` | POST | Create mission: `{"title":"...","description":"...","priority":"normal","source":"dashboard"}` |
| `/api/missions/{id}` | PATCH | Update status: `{"status":"backlog|running|done"}` |
| `/api/missions/{id}` | DELETE | Delete mission |
| `/api/missions/clear-completed` | POST | Remove all done missions |

### Stream Deck Integration

Add a Stream Deck button to queue quick tasks:

**System → Open:**
- **Executable:** `powershell.exe`
- **Arguments:** `-Command "& ~/.openclaw/skills/streamdeck/plugin-v5-sdk/add-mission.ps1 -Title 'Quick Task' -Description 'From Stream Deck' -Priority 'normal'"`

Or use the batch wrapper:
- **Executable:** `%~dp0add-mission.bat`
- **Arguments:** `"Task Title" "Description" "normal"`

Storage location: `~/.openclaw/streamdeck-mission-queue.json`

## API Reference

**TTS:** `POST /tts` with `{"text": "...", "voice": "default"}`

**Spawn:** `POST /spawn` with `{"task": "...", "agentId": "main"}`

**Status:** `GET /status`

See [references/API.md](references/API.md) for full reference.

## Hardware Support

- Stream Deck Mini (6 keys)
- Stream Deck MK.2 (15 keys)
- Stream Deck Plus (15 keys + 4 dials)
- Stream Deck XL (32 keys)
- Stream Deck Pedal (3 pedals)

## Resources

- **Setup Scripts:** `scripts/` (auto-setup, detect, install, generate)
- **Icons:** `assets/icons/` (72×72 PNG)
- **Detailed Docs:** `references/`
- **Marketing:** `marketing/` (store listing, pricing, social)
- **Plugin Code:** `plugin/`, `plugin-v3/`