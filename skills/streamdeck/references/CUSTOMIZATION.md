# Stream Deck Customization Guide

Advanced customization options for OpenClaw Stream Deck integration.

## Creating Custom Buttons

### Basic Custom Action

1. Open Stream Deck software
2. Drag "Open System" or "Website" action to button
3. Configure:
   - **App**: `powershell.exe`
   - **Arguments**: `-Command "& ~/.openclaw/skills/streamdeck/scripts/your-script.ps1"`

### Using BarRaider Advanced Launcher

For complex actions:

1. Install BarRaider Windows Utils
2. Use "Launch" action
3. Set:
   - Executable: `powershell.exe`
   - Arguments: `-ExecutionPolicy Bypass -File "C:\path\to\script.ps1"`

### Multi-Actions

Create button sequences:

1. Install BarRaider Stream Deck Tools
2. Use "Multi Action" button
3. Add steps:
   - Launch OpenClaw
   - Wait 2 seconds
   - Spawn agent
   - Send message

## Custom Scripts

### spawn-coding.ps1

```powershell
$task = $args[0]
openclaw sessions spawn --agent main --task "Code: $task"
```

### quick-message.ps1

```powershell
$message = $args[0]
openclaw message send --to telegram --message $message
```

### auto-profile.ps1

Switch profiles based on OpenClaw activity:

```powershell
$status = openclaw status --json | ConvertFrom-Json
if ($status.Sessions -gt 0) {
    streamdeck.exe switch-profile "OpenClaw Active"
}
```

## Conditional Buttons

Use BarRaider to show/hide based on state:

- Hide "Restart" when gateway stopped
- Show "Spawn" only when session active
- Dim buttons when OpenClaw offline

## Icon Customization

### Create Custom Icons

1. Design 72×72 PNG
2. High contrast for visibility
3. Place in `assets/icons/custom/`
4. Reference in button config

### Icon Color Coding

- Blue: AI functions (TTS, spawn, models)
- Green: System (restart, status, config)
- Orange: Tools (search, memory, browser)
- Red: Alerts (errors, offline)

## Gateway Configuration

Edit `plugin/webhooks.ps1`:

```powershell
$GatewayUrl = "http://127.0.0.1:18790"
$Headers = @{
    "Authorization" = "Bearer YOUR_TOKEN"
}
```

## Profile Layouts

### OpenClaw Control (15 keys)

```
[TTS] [Spawn] [Status] [Models] [Subagents]
[Node] [Restart] [Config] [Session] [Search]
[Memory] [Coding] [Audio] [Message] [Browser]
```

### OpenClaw Command Center (32 keys)

Full control surface with:
- Quick session switching
- Model selection
- Node camera controls
- Memory management
- Advanced web tools

### OpenClaw Studio (Plus)

For content creators:
- Dials: Volume, Brightness, Zoom, Scroll
- Keys: TTS, spawn, quick actions
- Dial press: Profile switching