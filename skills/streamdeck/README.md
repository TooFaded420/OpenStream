# OpenClaw Stream Deck Integration

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue.svg)](https://docs.microsoft.com/powershell/)

Control your OpenClaw AI assistant directly from Elgato Stream Deck hardware.

![OpenClaw Stream Deck](https://img.shields.io/badge/OpenClaw-Stream%20Deck-coral)

## 🎬 Overview

This skill provides complete Stream Deck integration for OpenClaw, allowing you to:
- **Spawn AI agents** with a single button press
- **Toggle TTS** (text-to-speech) on/off instantly  
- **Check system status** at a glance
- **Switch AI models** without typing commands
- **Control your entire OpenClaw setup** from physical keys

**Perfect for:** Developers, power users, streamers, and anyone who wants tactile AI control.

## ✨ Features

| Feature | Description |
|---------|-------------|
| 🎛️ **Auto-Detection** | Automatically finds all connected Stream Decks |
| 🔧 **One-Click Setup** | PowerShell script installs everything automatically |
| 🎨 **Custom Icons** | 10+ OpenClaw-themed icons in coral red |
| ⚡ **15 Actions** | TTS, spawn, status, models, nodes, restart, config, session, search, memory, coding, audio, message, browser |
| ♿ **Accessible** | WCAG 2.1 AA compliant, color-blind friendly |
| 🖥️ **Multi-Device** | Supports MK.2, XL, Plus, and Mini models |

## 🚀 Quick Start

### Prerequisites

- Windows 10/11
- [Elgato Stream Deck](https://www.elgato.com/stream-deck) hardware & software
- [OpenClaw](https://github.com/openclaw/openclaw) installed and running
- PowerShell 5.1 or higher

### Installation

1. **Clone or download** this repository:
```powershell
git clone https://github.com/yourusername/openclaw-streamdeck.git
cd openclaw-streamdeck
```

2. **Run the auto-setup** (as Administrator):
```powershell
powershell -ExecutionPolicy Bypass -File scripts/auto-setup-v3.ps1
```

3. **Import profiles** into Stream Deck software:
   - Open Stream Deck app
   - Profile dropdown → Import
   - Select profiles from `~/.openclaw/streamdeck-profiles/`

4. **Done!** Your Stream Deck now controls OpenClaw.

## 🎮 Button Actions

### AI Control
| Button | Action |
|--------|--------|
| 🔊 TTS | Toggle text-to-speech |
| 🤖 Spawn | Spawn a sub-agent |
| 📊 Status | Check OpenClaw status |
| 🧠 Models | List available AI models |
| ⚡ Subagents | View active sub-agents |

### System Tools
| Button | Action |
|--------|--------|
| 📡 Nodes | Check paired node status |
| 🔄 Restart | Restart OpenClaw gateway |
| ⚙️ Config | View configuration |
| 💬 Session | Show session info |

### Web & Memory
| Button | Action |
|--------|--------|
| 🔍 Search | Quick web search |
| 🧠 Memory | Search memory database |
| 💻 Coding | Spawn coding agent |
| 🎙️ Audio | Send TTS audio |
| 📤 Message | Send message |
| 🌐 Browser | Open browser control |

## 🖼️ Icons

All icons are **72×72 pixels** with OpenClaw's signature **coral red (#ff5c5c)**:

- ✅ High contrast (WCAG AA compliant)
- ✅ Color-blind friendly (shape-based recognition)
- ✅ Transparent backgrounds
- ✅ Consistent visual weight

Located in `assets/icons/`

## 🔧 Manual Installation

If auto-setup doesn't work:

1. **Install required plugins** from Stream Deck Marketplace:
   - BarRaider Windows Utils
   - BarRaider Stream Deck Tools
   - BarRaider Advanced Launcher
   - Audio Meter by Fred Emmott

2. **Run detection script**:
```powershell
.\scripts\detect-decks.ps1
```

3. **Generate profiles**:
```powershell
.\scripts\generate-profiles.ps1
```

4. **Import profiles** manually through Stream Deck software

## 📦 GitHub Release

- Release readiness and gateway routing implications:
  - `docs/GITHUB_RELEASE_READINESS.md`
- Packaging command:

```powershell
.\scripts\package-v5-release.ps1 -Version 5.4.0
```

## 🎨 Customization

### Creating Custom Buttons

1. In Stream Deck software, drag "Open System" action to a button
2. Set executable: `powershell.exe`
3. Arguments: `-ExecutionPolicy Bypass -File "C:\path\to\custom-action.ps1"`

### Using BarRaider Advanced Launcher

For complex actions:
1. Install BarRaider Windows Utils
2. Use "Launch" action
3. Set executable to your custom PowerShell script

### Color Scheme

- **Primary:** `#ff5c5c` (OpenClaw Coral)
- **Secondary:** `#14b8a6` (Teal)
- **White:** `#ffffff` (Main elements)
- **Background:** Transparent

## 📁 File Structure

```
openclaw-streamdeck/
├── scripts/
│   ├── auto-setup-v3.ps1      # Main setup script
│   ├── detect-decks.ps1       # Hardware detection
│   ├── generate-profiles.ps1  # Profile generator
│   └── generate-icons.ps1     # Icon generator
├── assets/
│   ├── icons/                 # 72x72 PNG icons
│   │   ├── tts.png
│   │   ├── spawn.png
│   │   ├── status.png
│   │   └── ... (10 total)
│   └── youtube-script.md      # Video script template
├── SKILL.md                   # Full documentation
├── README.md                  # This file
└── LICENSE                    # MIT License
```

## 🎥 YouTube Video

Want to see it in action? Check out our video script in `assets/youtube-script.md`

Perfect for:
- Demoing your setup
- Teaching others to install
- Sharing with the community

## 🐛 Troubleshooting

### Buttons not working?
1. Check OpenClaw gateway is running: `openclaw gateway status`
2. Verify gateway URL in plugin settings
3. Test manually: `Invoke-RestMethod -Uri "http://127.0.0.1:18790/status" -Method Get`

### Profile not importing?
1. Restart Stream Deck software
2. Check profile JSON syntax
3. Try manual copy to `%APPDATA%/Elgato/StreamDeck/ProfilesV2/`

### Plugin not showing?
1. Restart Stream Deck after plugin install
2. Check plugin folder: `%APPDATA%/Elgato/StreamDeck/Plugins/`
3. Re-run install script as Administrator

## 🤝 Contributing

Contributions welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Submit a pull request

## 📄 License

MIT License - see [LICENSE](LICENSE) file

## 🔗 Links

- [OpenClaw Documentation](https://docs.openclaw.ai)
- [OpenClaw GitHub](https://github.com/openclaw/openclaw)
- [Stream Deck Marketplace](https://apps.elgato.com)
- [BarRaider Plugins](https://github.com/barraider)

## 🙏 Credits

- BarRaider for excellent Stream Deck plugins
- Fred Emmott for Audio Meter
- OpenClaw community for testing and feedback

---

**Made with 🦞 by the OpenClaw Community**
