# Demo & Visual Guide

See the Stream Deck plugin in action.

## 🎬 Quick Demo (2 minutes)

### Setup Flow

```
[User clicks INSTALLER.ps1]
        ↓
[Auto-detects Stream Deck]
        ↓
[Installs plugin]
        ↓
[Generates profiles]
        ↓
[Tests connection]
        ↓
[✓ Ready to use!]
```

### Button Press Flow

```
[Press "Spawn Agent" button]
        ↓
[Stream Deck → OpenClaw API]
        ↓
[POST /spawn {"task":"..."}]
        ↓
[Agent spawned]
        ↓
[Response shown on Stream Deck]
        ↓
[Agent starts working]
```

## 📸 Screenshots

### Installer Running

```
╔══════════════════════════════════════════════════════════╗
║   OpenClaw Stream Deck Plugin Installer v3.0.0          ║
╚══════════════════════════════════════════════════════════╝

[10:15:42] → Checking Stream Deck software...
[10:15:42] ✓ Found Stream Deck at: C:\Program Files\...
[10:15:42] ✓ Stream Deck already running

[10:15:47] → Detecting connected Stream Decks...
[10:15:47] ✓ Stream Deck detected!

[10:15:52] → Installing OpenClaw Plugin...
[10:15:53] ✓ OpenClaw plugin installed

[10:15:58] → Generating OpenClaw profiles...
[10:15:59] ✓ Created: OpenClaw-Control-MK2
[10:16:00] ✓ Profile installed to Stream Deck

╔══════════════════════════════════════════════════════════╗
║   ✓ Installation Complete!                             ║
╚══════════════════════════════════════════════════════════╝
```

### Stream Deck Layout

**Developer Profile (15 keys):**

```
┌─────┬─────┬─────┬─────┬─────┐
│ 🎤  │ 🤖  │ 📊  │ 🧠  │ ⚡  │  ← Row 1: Quick actions
│ TTS │Spawn│Stat │Mods │Subs │
├─────┼─────┼─────┼─────┼─────┤
│ 💻  │ 🐛  │ 🔍  │ 🌐  │ 💬  │  ← Row 2: Tools
│Code │Debug│Mem  │Web  │Chat │
├─────┼─────┼─────┼─────┼─────┤
│ 📡  │ 🔄  │ ⚙️  │ 📝  │ 🌐  │  ← Row 3: System
│Node │Rest │Conf │Git  │Brw  │
└─────┴─────┴─────┴─────┴─────┘
```

### Button Configuration

**Inspector Panel:**

```
┌──────────────────────────────┐
│  OpenClaw Action             │
├──────────────────────────────┤
│                              │
│  Action:                     │
│  ┌────────────────────────┐  │
│  │ ☑ Status Check        │  │
│  │ ☐ Toggle TTS          │  │
│  │ ☐ Spawn Agent         │  │
│  │ ☐ List Models         │  │
│  │ ☐ Restart Gateway     │  │
│  └────────────────────────┘  │
│                              │
│  [Advanced Settings...]      │
│                              │
└──────────────────────────────┘
```

## 🎥 Video Walkthrough

### 1. Installation (30s)

```
1. Download from GitHub
2. Right-click → "Run with PowerShell"
3. Watch installer work
4. Done!
```

### 2. First Use (60s)

```
1. Open Stream Deck software
2. See "OpenClaw" profile
3. Drag action to button
4. Configure endpoint
5. Press button
6. See result!
```

### 3. Customization (30s)

```
1. Right-click button
2. Set custom icon
3. Edit action settings
4. Rearrange buttons
5. Save profile
```

## 🖼️ Visual Assets

### Icons

Located in `assets/icons/`:

| Icon | File | Use Case |
|------|------|----------|
| 🔊 | `tts.png` | Text-to-speech |
| 🤖 | `spawn.png` | Spawn agent |
| 📊 | `status.png` | Status check |
| 🧠 | `models.png` | Model switching |
| ⚡ | `subagents.png` | Subagent control |
| 📡 | `nodes.png` | Node status |
| 🔄 | `restart.png` | Restart gateway |
| ⚙️ | `config.png` | Configuration |
| 💬 | `session.png` | Session info |
| 🔍 | `websearch.png` | Web search |

### Colors

- **Blue (#58a6ff):** AI functions (TTS, spawn, models)
- **Green (#3fb950):** System functions (status, restart, config)
- **Orange (#d29922):** Tools (search, memory, browser)
- **Red (#f85149):** Alerts (errors, offline)

## 📱 Real-World Usage

### Scenario 1: Coding Session

```
User: *Presses "Code Review" button*
Stream Deck: *Sends request to OpenClaw*
OpenClaw: *Spawns coding agent*
Agent: *Analyzes current file*
Result: *Suggestions appear in editor*
```

### Scenario 2: Quick Question

```
User: *Presses "TTS Toggle"*
Stream Deck: *Enables TTS*
User: *Presses "Spawn Agent"*
OpenClaw: *Creates agent*
User: *Speaks question*
Agent: *Responds via TTS*
```

### Scenario 3: System Check

```
User: *Presses "Status Check"*
Stream Deck: *Shows status on button*
User: *Sees 3 sessions, 2 models*
User: *Presses "Models"*
Stream Deck: *Shows model list*
User: *Switches to Kimi K2.5*
```

## 🎨 Customization Examples

### Before vs After

**Default:**
```
┌─────┐
│ ??? │  ← Generic icon
└─────┘
```

**Customized:**
```
┌─────┐
│ 🎤  │  ← Clear icon
│ TTS │  ← Label
└─────┘
```

## 📊 Performance

| Action | Response Time |
|--------|---------------|
| Status Check | <100ms |
| TTS Toggle | <200ms |
| Spawn Agent | <500ms |
| Model Switch | <300ms |
| Web Search | <2s |

## 🔗 Links

- **Live Demo:** [YouTube link]
- **Setup Tutorial:** [YouTube link]
- **Example Configs:** [GitHub folder]
- **Icon Pack:** [Download link]

---

**Want to see it on your hardware?** Run the installer! 🚀