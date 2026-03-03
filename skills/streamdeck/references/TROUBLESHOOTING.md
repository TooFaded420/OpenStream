# Troubleshooting Guide

Common issues and solutions for Stream Deck + OpenClaw integration.

## Quick Diagnostics

Run diagnostic script:

```powershell
."scripts/diagnose.ps1"
```

This generates `streamdeck-diagnosis.json` with system status.

## Common Issues

### Buttons Not Responding

**Symptoms:** Pressing buttons does nothing.

**Check 1: Gateway Status**

```powershell
openclaw gateway status
```

Expected: `Runtime: running`

If stopped:
```powershell
openclaw gateway start
```

**Check 2: Gateway URL**

Verify URL in `plugin/webhooks.ps1`:

```powershell
$GatewayUrl = "http://127.0.0.1:18790"  # Must match your gateway port
```

**Check 3: Test Webhook**

```powershell
Invoke-RestMethod -Uri "http://127.0.0.1:18790/status" -Method Get
```

Should return JSON status.

**Check 4: Firewall**

Ensure port 18790 is not blocked:

```powershell
Test-NetConnection -ComputerName 127.0.0.1 -Port 18790
```

### Profile Not Importing

**Symptoms:** "Import failed" or profile doesn't appear.

**Solution 1: Update Stream Deck Software**

Ensure latest version: https://www.elgato.com/downloads

**Solution 2: Check JSON Syntax**

Validate profile JSON:

```powershell
Get-Content "~/.openclaw/streamdeck-profiles/OpenClaw-Control.sdProfile/manifest.json" | ConvertFrom-Json
```

If error, regenerate:

```powershell
."scripts/generate-profiles.ps1"
```

**Solution 3: Manual Import**

1. Close Stream Deck software
2. Copy profile folder to:
   ```
   %APPDATA%/Elgato/StreamDeck/ProfilesV2/
   ```
3. Restart Stream Deck software

### Plugin Not Showing

**Symptoms:** OpenClaw plugin not in Stream Deck actions list.

**Solution 1: Restart Stream Deck**

Fully exit and restart Stream Deck software.

**Solution 2: Check Plugin Folder**

Verify installation:

```powershell
Get-ChildItem "$env:APPDATA\Elgato\StreamDeck\Plugins\" | Where-Object { $_.Name -like "*openclaw*" }
```

**Solution 3: Reinstall with Admin**

```powershell
# Run PowerShell as Administrator
."scripts/install-plugins.ps1"
```

**Solution 4: Manual Install**

1. Download plugin from releases
2. Double-click `.streamDeckPlugin` file
3. Restart Stream Deck

### Gateway Token Mismatch

**Symptoms:** "Unauthorized" errors.

**Solution:**

```powershell
# Run as Administrator
openclaw gateway install --force
```

This syncs config token with service token.

### Security Errors (ws://)

**Symptoms:** "SECURITY ERROR: Gateway URL uses plaintext ws://"

**Solution 1: Use Loopback Bind**

```powershell
openclaw config set gateway.bind loopback
openclaw gateway restart
```

**Solution 2: Accept Trade-off**

Use `lan` bind for convenience (less secure):

```powershell
openclaw config set gateway.bind lan
```

### Port Already in Use

**Symptoms:** "Port 18790 is already in use"

**Solution 1: Find and Kill Process**

```powershell
Get-NetTCPConnection -LocalPort 18790 | Select-Object OwningProcess
Stop-Process -Id <PID> -Force
```

**Solution 2: Use Different Port**

```powershell
openclaw config set gateway.port 18791
openclaw gateway restart
```

Update `plugin/webhooks.ps1` with new port.

### TTS Not Working

**Symptoms:** TTS button presses but no audio.

**Check 1: TTS Provider**

```powershell
openclaw config get messages.tts.provider
```

Should be: `edge`, `openai`, or `elevenlabs`

**Check 2: Audio Output**

Windows audio settings:
- Correct output device selected
- Volume not muted
- Not in Do Not Disturb

**Check 3: Test Direct**

```powershell
openclaw tts "Test message" --voice default
```

### Spawn Failing

**Symptoms:** "Spawn failed" or "Gateway timeout"

**Check 1: Gateway Running**

```powershell
openclaw gateway status
```

**Check 2: Model Available**

```powershell
openclaw models list
```

**Check 3: Resource Limits**

Check if too many agents:

```powershell
openclaw subagents list
```

If >10 active, wait or kill some:

```powershell
openclaw subagents kill <key>
```

### Icons Not Showing

**Symptoms:** Buttons show default icon instead of custom.

**Solution 1: Verify Icon Path**

Check icons exist:

```powershell
Get-ChildItem "~/.openclaw/skills/streamdeck/assets/icons/"
```

**Solution 2: Re-import Profile**

1. Delete old profile from Stream Deck
2. Re-import from `~/.openclaw/streamdeck-profiles/`

**Solution 3: Manual Icon Set**

1. Right-click button
2. "Set from File"
3. Select PNG from `assets/icons/`

## Debug Mode

Enable verbose logging:

```powershell
$env:OPENCLAW_DEBUG = "1"
."scripts/auto-setup-v3.ps1"
```

Logs saved to `~/.openclaw/logs/`.

## Getting Help

### Logs Location

Stream Deck logs:
```
%APPDATA%/Elgato/StreamDeck/logs/
```

OpenClaw logs:
```
%USERPROFILE%/.openclaw/logs/
/tmp/openclaw/
```

### Support Channels

- OpenClaw docs: https://docs.openclaw.ai
- Stream Deck docs: https://help.elgato.com
- Issues: https://github.com/openclaw/openclaw/issues

### Report Bug

Include:
1. Stream Deck model
2. OpenClaw version (`openclaw --version`)
3. Error message
4. Diagnostic output (`scripts/diagnose.ps1`)
5. Steps to reproduce