# OpenClaw SDK v5 with Dial Pack v1

## Button Actions (All Devices)

| Position | Action | Function |
|----------|--------|----------|
| Row 1-1 | Status | Check gateway status + latency |
| Row 1-2 | TTS | Toggle TTS on/off |
| Row 1-3 | Spawn | Spawn helper agent |
| Row 1-4 | Session | Show current model |
| Row 1-5 | Search | Quick web search |
| Row 2-1 | Agents | Count active subagents |
| Row 2-2 | Nodes | Count paired nodes |
| Row 2-3 | Reconnect | Ping gateway |

## Dial Actions (Stream Deck Plus/Neo only)

### Dial 1: Model Controller
- **Rotate**: Cycle through available models
  - `synthetic/hf:nvidia/Kimi-K2.5-NVFP4`
  - `synthetic/vertex/gemini-2.5-pro`
  - `anthropic/claude-3.5-sonnet`
  - `openai/gpt-4o`
- **Press**: Apply selected model

### Dial 2: TTS Controller
- **Rotate**: Adjust TTS volume (5% steps)
- **Press**: Toggle mute

### Dial 3: Agent Navigator
- **Rotate**: Cycle through active subagents
- **Press**: Kill selected subagent

### Dial 4: Profile Switcher
- **Rotate**: Cycle profiles (`default`, `coding`, `gaming`, `media`)
- **Press**: Ping gateway + show latency

## Stream Deck Plus Layout

```
+-------+-------+-------+-------+
| Dial1 | Dial2 | Dial3 | Dial4 |
| Model |  TTS  |Agents |Profile|
+-------+-------+-------+-------+
| Status|  TTS  | Spawn |Session| Search |
|-------|-------|-------|-------|--------|
| Agents| Nodes | Reconn|       |        |
|-------|-------|-------|-------|--------|
|       |       |       |       |        |
+-------+-------+-------+-------+
```

## Installation

1. Copy `com.openclaw.v5.sdPlugin` folder to:
   `%appdata%\Elgato\StreamDeck\Plugins\`

2. Restart Stream Deck software

3. Plugin appears under **OpenClaw** category

## Logs

Runtime logs: `%TEMP%\openclaw-v5-runtime.log`
Launch logs: `%TEMP%\openclaw-v5-launch.log`

## Troubleshooting

- **Plugin not appearing**: Restart Stream Deck software
- **"OFF" on buttons**: Gateway not running at `127.0.0.1:18790`
- **Dials not working**: Verify device is Stream Deck Plus or Neo

## Version History

- v5.2.0: Added Dial Pack v1 with 4 encoder actions
- v5.1.0: Initial SDK v5 release
