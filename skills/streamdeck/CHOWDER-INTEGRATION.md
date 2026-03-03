# Chowder Integration - Live Activity v4

Stream Deck plugin now includes all Chowder patterns from https://github.com/newmaterialco/chowder-iOS

## Features

### ✅ Live Activity / Thinking Steps
- Buttons show real-time tool execution progress
- Animated thinking indicators while agents work
- Extracts tool calls from `chat.history` responses
- Visual feedback: "Spawning..." → "Running..." → "Complete!"

### ✅ Demo Mode
- Test buttons without OpenClaw connection
- Simulated responses and timing
- Toggle on/off with dedicated button
- Auto-exit demo when real connection established

### ✅ Reconnection Logic
- Exponential backoff (3s → 6s → 12s → 24s → 30s)
- Auto-retry up to 5 attempts
- Visual indicator shows reconnect attempt count
- Manual reconnect button available

### ✅ Identity Sync
- Reads `IDENTITY.md` and `SOUL.md` from workspace
- Displays agent emoji, name, creature type
- Updates dynamically when files change
- Shows in button titles

### ✅ Lifecycle States
| State | Icon | Color | Duration |
|-------|------|-------|----------|
| Idle | - | Black | Persistent |
| Active | ● | Cyan | Until processing |
| Processing | ◐ | Amber | During tool exec |
| Complete | ✓ | Green | 2 seconds |
| Error | ✗ | Red | Until dismissed |
| Demo | DEMO | Magenta | Persistent |

### ✅ Tool Summary Extraction
- Parses `content[]` arrays for tool calls
- Shows "exec completed (859ms)" style messages
- Tracks web_search, spawn, exec, web_fetch tool states

## Installation

```powershell
# Copy v4 plugin to Stream Deck
Copy-Item -Recurse "~/.openclaw/workspace/skills/streamdeck/plugin-v4" `
    "$env:APPDATA\Elgato\StreamDeck\Plugins\com.openclaw.streamdeck.v4.sdPlugin"

# Restart Stream Deck software
```

## Button Layout

### Row 1: Core Actions
1. **TTS Toggle** - Toggle text-to-speech
2. **Spawn Agent** - Spawn sub-agent with live activity
3. **Identity Sync** - Show agent emoji/name

### Row 2: Status & Info
4. **Status Check** - Gateway status with reconnection
5. **Session Info** - Current model
6. **Subagents** - Active agent count

### Row 3: Tools & Demo
7. **Web Search** - Search with progress
8. **Nodes** - Paired node count
9. **Demo Toggle** - Switch demo mode

### Row 4: Advanced
10. **Force Reconnect** - Manual reconnect

## Configuration

Edit `manifest.json` or pass settings:

```json
{
  "gateway": "http://192.168.1.148:18790",
  "demoMode": false,
  "demoModeAutoOff": true
}
```

## Comparison with Chowder iOS

| Feature | Chowder iOS | OpenClaw Stream Deck |
|---------|-------------|---------------------|
| Live Activity | ✅ Inline chat | ✅ Button animations |
| Thinking Steps | ✅ Text + haptic | ✅ LED + title |
| Demo Mode | ✅ No connection | ✅ No connection |
| Reconnection | ✅ Auto-backoff | ✅ Auto-backoff |
| Identity Sync | ✅ Header display | ✅ Button title |
| WebSocket | ✅ Streaming | ✅ Polling fallback |

## Technical Notes

- Uses PowerShell runspaces for WebSocket background threads
- Falls back to HTTP polling if WebSocket unavailable
- Demo mode simulates realistic tool execution timing
- Identity sync runs on first button press per session
