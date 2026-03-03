# Troubleshooting Guide (Quick Reference)

Quick fixes for common issues.

## 🔴 Critical Issues

### "ExecutionPolicy" Error

**Symptom:** `cannot be loaded because running scripts is disabled`

**Fix:**
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

**Or bypass for this session:**
```powershell
powershell -ExecutionPolicy Bypass -File INSTALLER.ps1
```

---

### Gateway Not Found

**Symptom:** `Cannot connect to gateway` or `Connection refused`

**Check:**
```powershell
openclaw gateway status
```

**If stopped:**
```powershell
openclaw gateway start
```

**If wrong port:**
```powershell
openclaw config set gateway.port 18790
openclaw gateway restart
```

---

### Stream Deck Not Detected

**Symptom:** `Stream Deck software not found`

**Fix:**
1. Download from [elgato.com](https://www.elgato.com/downloads)
2. Install and launch
3. Connect hardware
4. Re-run installer

---

## 🟡 Common Issues

### Plugin Not Showing

**Check 1:** Restart Stream Deck
- Right-click tray icon → Quit
- Reopen Stream Deck
- Wait 10 seconds

**Check 2:** Verify installation
```powershell
Test-Path "$env:APPDATA\Elgato\StreamDeck\Plugins\com.openclaw.webhooks.sdPlugin"
```

**Check 3:** Run as Admin
```powershell
# Right-click PowerShell → "Run as Administrator"
.\INSTALLER.ps1
```

---

### Buttons Not Working

**Test 1:** Gateway connection
```powershell
Invoke-RestMethod -Uri "http://127.0.0.1:18790/status" -Method Get
```

**Should return:** JSON with status info

**Test 2:** Button configuration
- Right-click button in Stream Deck
- Check "Action" is set
- Verify endpoint is correct

**Test 3:** Manual API call
```powershell
$Body = @{ text = "Test" } | ConvertTo-Json
Invoke-RestMethod -Uri "http://127.0.0.1:18790/tts" -Method Post -Body $Body -ContentType "application/json"
```

---

### Port Already in Use

**Symptom:** `Port 18790 is already in use`

**Find process:**
```powershell
Get-NetTCPConnection -LocalPort 18790 | Select-Object OwningProcess
```

**Kill process:**
```powershell
Stop-Process -Id <PID> -Force
```

**Or use different port:**
```powershell
openclaw config set gateway.port 18791
# Update plugin.ps1 with new port
```

---

### Icons Not Loading

**Symptom:** Default icon instead of custom

**Fix:**
1. Verify PNG files in `assets/icons/`
2. Check filenames match manifest
3. Right-click button → "Set from File"
4. Select correct PNG

---

## 🟢 Minor Issues

### Slow Response

**Cause:** Network latency or gateway overload

**Fix:**
- Check gateway load: `openclaw status`
- Reduce active sessions
- Restart gateway: `openclaw gateway restart`

---

### TTS Not Playing

**Check 1:** Windows audio
- Volume not muted
- Correct output device
- Not in Focus Assist

**Check 2:** TTS provider
```powershell
openclaw config get messages.tts.provider
# Should be: edge, openai, or elevenlabs
```

**Check 3:** Test directly
```powershell
openclaw tts "Test message"
```

---

### Model Switch Failed

**Symptom:** Model doesn't change

**Fix:**
```powershell
# Check available models
openclaw models list

# Switch manually
openclaw config set agents.defaults.model.primary synthetic/hf:moonshotai/Kimi-K2.5

# Restart gateway
openclaw gateway restart
```

---

## 🔧 Diagnostic Commands

### Full System Check

```powershell
# Check Stream Deck
Get-Process "StreamDeck" -ErrorAction SilentlyContinue

# Check OpenClaw
openclaw --version
openclaw gateway status

# Check plugin
Get-ChildItem "$env:APPDATA\Elgato\StreamDeck\Plugins\com.openclaw*"

# Check profiles
Get-ChildItem "$env:APPDATA\Elgato\StreamDeck\ProfilesV2\OpenClaw*"

# Test API
Invoke-RestMethod -Uri "http://127.0.0.1:18790/status" -Method Get
```

### Generate Diagnostic Report

```powershell
.\diagnose.ps1
# Creates streamdeck-diagnosis.json
```

---

## 📞 Still Stuck?

**Step 1:** Check logs
```
# Stream Deck logs
%APPDATA%\Elgato\StreamDeck\logs\

# OpenClaw logs
%USERPROFILE%\.openclaw\logs\
```

**Step 2:** Run test suite
```powershell
.\TEST.ps1
```

**Step 3:** Get help
- OpenClaw docs: https://docs.openclaw.ai
- Issues: https://github.com/openclaw/openclaw/issues
- Discord: https://discord.com/invite/clawd

**Step 4:** Reset everything
```powershell
# Remove plugin
Remove-Item "$env:APPDATA\Elgato\StreamDeck\Plugins\com.openclaw.webhooks.sdPlugin" -Recurse -Force

# Remove profiles
Remove-Item "$env:APPDATA\Elgato\StreamDeck\ProfilesV2\OpenClaw*" -Recurse -Force

# Re-run installer
.\INSTALLER.ps1
```

---

## ✅ Verification Checklist

After fixing issues, verify:

- [ ] Stream Deck software running
- [ ] OpenClaw gateway running
- [ ] Plugin files present
- [ ] Gateway URL correct
- [ ] Buttons configured
- [ ] Actions work when pressed
- [ ] Icons display correctly

**All checked?** You're good to go! 🎉