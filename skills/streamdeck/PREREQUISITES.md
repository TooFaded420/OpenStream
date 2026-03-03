# Prerequisites

Check these before installing to ensure smooth setup.

## Required Software

| Software | Version | Download | Status |
|----------|---------|----------|--------|
| **Stream Deck** | Latest | [elgato.com](https://www.elgato.com/downloads) | ⚠️ Check |
| **PowerShell** | 5.1+ | Built-in Windows | ✅ Usually OK |
| **OpenClaw** | Latest | `npm install -g openclaw` | ⚠️ Check |

## Quick Checks

### 1. Stream Deck Software

```powershell
# Check if installed
Get-Command "StreamDeck" -ErrorAction SilentlyContinue

# Or check paths:
Test-Path "$env:ProgramFiles\Elgato\StreamDeck\StreamDeck.exe"
```

**Not installed?** Download from [elgato.com](https://www.elgato.com/downloads)

### 2. PowerShell Version

```powershell
$PSVersionTable.PSVersion
# Need: Major = 5 or higher
```

**Update:** Windows 10/11 have this by default.

### 3. OpenClaw CLI

```powershell
openclaw --version
# Should show version number
```

**Not installed?**
```bash
npm install -g openclaw
# Or download from GitHub releases
```

### 4. OpenClaw Gateway

```powershell
openclaw gateway status
# Should show: Runtime: running
```

**Not running?**
```powershell
openclaw gateway start
```

### 5. Execution Policy (PowerShell)

```powershell
Get-ExecutionPolicy
# If "Restricted", run as Admin:
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

## Hardware Requirements

| Device | Keys | Supported | Tested |
|--------|------|-----------|--------|
| Stream Deck Mini | 6 | ✅ | ✅ |
| Stream Deck MK.2 | 15 | ✅ | ✅ |
| Stream Deck + | 15+4 | ✅ | ✅ |
| Stream Deck XL | 32 | ✅ | ✅ |
| Stream Deck Pedal | 3 | ✅ | ⚠️ |

## Network Requirements

- Localhost access (127.0.0.1)
- Port 18790 (default) open
- No firewall blocking

**Test:**
```powershell
Test-NetConnection -ComputerName 127.0.0.1 -Port 18790
```

## Pre-Install Checklist

- [ ] Stream Deck software installed and running
- [ ] OpenClaw CLI installed (`openclaw --version` works)
- [ ] OpenClaw gateway running (`openclaw gateway status` shows running)
- [ ] PowerShell execution policy allows scripts
- [ ] Stream Deck hardware connected

## Common Blockers

| Issue | Solution |
|-------|----------|
| "ExecutionPolicy" error | Run: `Set-ExecutionPolicy RemoteSigned -Scope CurrentUser` |
| "Command not found" | Add to PATH or use full path |
| "Port in use" | Change port: `openclaw config set gateway.port 18791` |
| "Access denied" | Run PowerShell as Administrator |

## Still Stuck?

Run diagnostics:
```powershell
.\diagnose.ps1
```

Or see [TROUBLESHOOTING.md](references/TROUBLESHOOTING.md)