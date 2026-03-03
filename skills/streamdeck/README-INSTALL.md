# OpenClaw Stream Deck Plugin

[![Version](https://img.shields.io/badge/version-3.0.0-blue.svg)](https://github.com/openclaw/openclaw)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

Control your OpenClaw AI assistant directly from Elgato Stream Deck hardware.

![Stream Deck Demo](assets/demo.png)

## ✨ Features

- 🎮 **One-click actions** — TTS, spawn agents, check status, restart gateway
- 🤖 **AI Control** — Spawn agents, switch models, manage subagents
- 🛠️ **System Tools** — Monitor nodes, search memory, web search
- 📊 **Real-time status** — Dynamic feedback on button displays
- 🔧 **Easy customization** — Add your own actions
- 🏠 **Home Assistant integration** — Control from your smart home

## 🚀 Quick Start (Automatic Install)

### Option 1: One-Click Installer (Recommended)

1. **Download** `INSTALLER.ps1`
2. **Right-click** → "Run with PowerShell"
3. **Done!** Restart Stream Deck software

```powershell
# Or run from command line:
.\INSTALLER.ps1
```

### Option 2: Manual Install

See [Manual Installation](#manual-installation) below.

## 📦 What's Included

| Feature | Description |
|---------|-------------|
| **TTS Toggle** | Enable/disable text-to-speech |
| **Spawn Agent** | Spawn sub-agent for tasks |
| **Status Check** | View OpenClaw system status |
| **Models** | List and switch AI models |
| **Subagents** | List active subagents |
| **Restart Gateway** | Restart OpenClaw gateway |
| **Nodes** | Check paired node status |
| **Memory Search** | Search OpenClaw memory |
| **Web Search** | Perform web searches |
| **Session Info** | View current session details |

## 🖥️ Supported Hardware

- ✅ Stream Deck Mini (6 keys)
- ✅ Stream Deck MK.2 (15 keys)
- ✅ Stream Deck + (15 keys + 4 dials)
- ✅ Stream Deck XL (32 keys)
- ✅ Stream Deck Pedal (3 pedals)

## 📋 Requirements

- Windows 10/11
- [Stream Deck software](https://www.elgato.com/downloads)
- OpenClaw installed and running
- PowerShell 5.1 or later

## 🔧 Manual Installation

If you prefer manual setup or the automatic installer doesn't work:

### Step 1: Download Files

Download the latest release:

```bash
git clone https://github.com/openclaw/openclaw.git
cd openclaw/skills/streamdeck
```

Or download ZIP from [Releases](https://github.com/openclaw/openclaw/releases)

### Step 2: Check Stream Deck Software

1. Install Stream Deck software from [elgato.com](https://www.elgato.com/downloads)
2. Launch Stream Deck application
3. Verify it's running in system tray

### Step 3: Install the Plugin

#### Method A: Automatic (via Script)

```powershell
# Run as Administrator (recommended)
.\scripts\install-plugins.ps1
```

#### Method B: Manual

1. **Create plugin directory:**
   ```
   %APPDATA%\Elgato\StreamDeck\Plugins\com.openclaw.webhooks.sdPlugin\
   ```

2. **Copy files:**
   - Copy `plugin-v3/manifest.json` → plugin directory
   - Copy `plugin-v3/plugin.ps1` → plugin directory
   - Copy `plugin-v3/inspector.html` → plugin directory
   - Copy `plugin/images/*` → plugin directory\images\

3. **Verify structure:**
   ```
   com.openclaw.webhooks.sdPlugin/
   ├── manifest.json
   ├── plugin.ps1
   ├── inspector.html
   └── images/
       ├── tts.png
       ├── spawn.png
       ├── status.png
       └── ...
   ```

### Step 4: Configure Gateway URL

Edit `plugin.ps1` and set your gateway URL:

```powershell
# Find this line (around line 15)
$Global:Gateways = @{
    "primary" = "http://127.0.0.1:18790"
    # Change if your gateway uses different port
}
```

**To find your gateway URL:**

```powershell
openclaw gateway status
```

Look for `Probe target: ws://...` or `Dashboard: http://...`

### Step 5: Restart Stream Deck

1. Right-click Stream Deck icon in system tray
2. Select "Quit"
3. Reopen Stream Deck application
4. Wait for plugins to load (10-15 seconds)

### Step 6: Add Actions

1. In Stream Deck software, look for **"OpenClaw Webhooks"** category
2. Drag **"OpenClaw Action"** to a button
3. Select desired action from dropdown:
   - Status Check
   - Toggle TTS
   - Spawn Agent
   - List Models
   - etc.

### Step 7: Test

Press a button — you should see:
- Visual feedback on Stream Deck
- Action executed in OpenClaw
- Result (if applicable)

## 🎨 Customization

### Adding Custom Actions

1. Edit `plugin.ps1`
2. Add to `$PrebuiltActions`:

```powershell
"my-custom-action" = @{
    Name = "My Action"
    Endpoint = "/custom.endpoint"
    Method = "POST"
    Icon = "custom.png"
    Body = @{ param1 = "value1" }
}
```

3. Restart Stream Deck

### Creating Profiles

Generate custom profiles:

```powershell
.\scripts\generate-profiles.ps1
```

Import generated `.sdProfile` folders:
1. Stream Deck software → Profile dropdown
2. Import → Select profile folder

### Custom Icons

1. Create 72×72 PNG icons
2. Place in `assets/icons/custom/`
3. Right-click button → "Set from File"
4. Select your icon

## 🔍 Troubleshooting

### Plugin Not Showing

**Symptom:** OpenClaw actions not in Stream Deck list

**Solutions:**
1. ✓ Restart Stream Deck software
2. ✓ Check plugin folder exists: `%APPDATA%\Elgato\StreamDeck\Plugins\`
3. ✓ Run as Administrator: `install-plugins.ps1`
4. ✓ Verify `manifest.json` syntax is valid JSON

### Buttons Not Working

**Symptom:** Press button, nothing happens

**Check:**
1. ✓ Gateway running: `openclaw gateway status`
2. ✓ Gateway URL correct in `plugin.ps1`
3. ✓ Port not blocked by firewall
4. ✓ Test: `Invoke-RestMethod http://127.0.0.1:18790/status`

### Gateway Connection Failed

**Symptom:** "Cannot connect to gateway"

**Fix:**
```powershell
# Check gateway
openclaw gateway status

# If stopped, start it
openclaw gateway start

# Check config
openclaw config get gateway.port
```

### Icons Not Loading

**Symptom:** Default icon instead of custom

**Fix:**
1. Verify PNG files in `images/` folder
2. Check filenames match manifest
3. Re-import profile

## 📚 Documentation

- [System Documentation](AGENT_JOURNAL_SYSTEM.md)
- [Customization Guide](references/CUSTOMIZATION.md)
- [Advanced Usage](references/ADVANCED.md)
- [API Reference](references/API.md)
- [Troubleshooting](references/TROUBLESHOOTING.md)

## 🏗️ Development

### Building from Source

```bash
# Clone repo
git clone https://github.com/openclaw/openclaw.git
cd openclaw/skills/streamdeck

# Install dependencies
.\scripts\install-plugins.ps1

# Test plugin
.\scripts\test-plugin.ps1
```

### Plugin Structure

```
com.openclaw.webhooks.sdPlugin/
├── manifest.json          # Plugin metadata
├── plugin.ps1            # Main script
├── inspector.html        # Settings UI
└── images/               # Button icons
    ├── tts.png
    ├── spawn.png
    └── status.png
```

### Adding New Actions

1. Edit `plugin-v3/openclaw-plugin-v3.ps1`
2. Add action to `$PrebuiltActions`
3. Update `inspector.html` options
4. Test locally
5. Submit PR

## 🤝 Contributing

Contributions welcome! Please:
1. Fork the repository
2. Create feature branch
3. Test on actual Stream Deck hardware
4. Submit PR with description

See [CONTRIBUTING.md](.github/CONTRIBUTING.md) for guidelines.

## 📄 License

MIT License - see [LICENSE](LICENSE) file.

## 🙏 Credits

- [BarRaider](https://github.com/barraider) - Stream Deck plugins
- [Fred Emmott](https://github.com/fredemmott) - Audio Meter plugin
- [Elgato](https://www.elgato.com) - Stream Deck SDK

## 🔗 Links

- 🌐 [OpenClaw Docs](https://docs.openclaw.ai)
- 🐛 [Issues](https://github.com/openclaw/openclaw/issues)
- 💬 [Discord](https://discord.com/invite/clawd)

---

**Built with ❤️ by the OpenClaw community**

*"Build once. Strengthen forever."*