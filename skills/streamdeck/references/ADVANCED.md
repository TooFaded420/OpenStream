# Advanced Stream Deck Usage

Power user features and automation for OpenClaw Stream Deck integration.

## Custom Plugin Development

### Building Custom Plugins

To extend OpenClaw integration:

1. Fork the skill repository
2. Add new actions to `actions/`
3. Update `manifest.json`
4. Submit PR

### Plugin Structure

```
com.openclaw.webhooks.sdPlugin/
├── manifest.json      # Plugin metadata
├── main.exe           # Entry point
├── actions/
│   ├── tts.js
│   ├── spawn.js
│   └── status.js
└── images/
    ├── tts.png
    ├── spawn.png
    └── status.png
```

### Manifest.json Example

```json
{
  "Name": "OpenClaw Integration",
  "Version": "1.0.0",
  "Actions": [
    {
      "Name": "TTS",
      "UUID": "com.openclaw.tts",
      "Icon": "images/tts.png"
    }
  ]
}
```

## Profile Switching Automation

### Auto-Switch Based on Activity

**auto-profile.ps1:**

```powershell
while ($true) {
    $status = openclaw status --json | ConvertFrom-Json
    
    if ($status.Sessions -gt 0 -and $status.ActiveSession -ne $currentProfile) {
        streamdeck.exe switch-profile "OpenClaw Active"
        $currentProfile = "OpenClaw Active"
    }
    elseif ($status.Sessions -eq 0 -and $currentProfile -ne "OpenClaw Idle") {
        streamdeck.exe switch-profile "OpenClaw Idle"
        $currentProfile = "OpenClaw Idle"
    }
    
    Start-Sleep -Seconds 5
}
```

### Schedule Profile Changes

**scheduled-profile.ps1:**

```powershell
$hour = (Get-Date).Hour

if ($hour -ge 9 -and $hour -lt 17) {
    streamdeck.exe switch-profile "OpenClaw Work"
} else {
    streamdeck.exe switch-profile "OpenClaw Personal"
}
```

## Conditional Button Logic

### State-Based Visibility

Use BarRaider to conditionally show/hide:

**Hide when offline:**
```powershell
$status = openclaw gateway status
if ($status -match "running") {
    # Show button
} else {
    # Hide button
}
```

**Dim when busy:**
```powershell
$sessions = openclaw sessions list --json | ConvertFrom-Json
if ($sessions.Count -gt 3) {
    # Dim buttons
}
```

## Multi-Gateway Support

### Switch Between Gateways

**switch-gateway.ps1:**

```powershell
param([string]$Target)

$gateways = @{
    "local" = "http://127.0.0.1:18790"
    "remote" = "http://100.92.222.41:18789"
}

$env:OPENCLAW_GATEWAY_URL = $gateways[$Target]
openclaw gateway status
```

## Webhook Integration

### Direct API Calls

**webhook-call.ps1:**

```powershell
$Uri = "http://127.0.0.1:18790/spawn"
$Body = @{
    task = "Analyze code"
    agentId = "main"
} | ConvertTo-Json

Invoke-RestMethod -Uri $Uri -Method Post -Body $Body -ContentType "application/json"
```

### Custom Webhook Server

**webhook-server.ps1:**

```powershell
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:8080/")
$listener.Start()

while ($listener.IsListening) {
    $context = $listener.GetContext()
    $request = $context.Request
    
    # Process request
    # Trigger OpenClaw actions
    
    $response = $context.Response
    $response.Close()
}
```

## Performance Optimization

### Cache Status Calls

**cached-status.ps1:**

```powershell
$cacheFile = "/tmp/openclaw-status.json"
$cacheDuration = 5  # seconds

if (Test-Path $cacheFile) {
    $age = (Get-Date) - (Get-Item $cacheFile).LastWriteTime
    if ($age.TotalSeconds -lt $cacheDuration) {
        Get-Content $cacheFile | ConvertFrom-Json
        return
    }
}

$status = openclaw status --json
$status | Out-File $cacheFile
$status | ConvertFrom-Json
```

### Parallel Actions

**parallel-spawn.ps1:**

```powershell
$tasks = @("Task 1", "Task 2", "Task 3")

$tasks | ForEach-Object -Parallel {
    openclaw sessions spawn --agent main --task $_
} -ThrottleLimit 3
```

## Troubleshooting Scripts

### Diagnostic Report

**diagnose.ps1:**

```powershell
$report = @{
    timestamp = Get-Date -Format "o"
    gateway = openclaw gateway status
    sessions = openclaw sessions list
    plugins = Get-ChildItem "$env:APPDATA\Elgato\StreamDeck\Plugins"
    profiles = Get-ChildItem "$env:APPDATA\Elgato\StreamDeck\ProfilesV2"
}

$report | ConvertTo-Json -Depth 10 | Out-File "streamdeck-diagnosis.json"
```

### Test All Buttons

**test-buttons.ps1:**

```powershell
$buttons = @("tts", "spawn", "status", "models", "nodes")

foreach ($button in $buttons) {
    Write-Host "Testing $button..."
    & "scripts/$button.ps1"
    Start-Sleep -Milliseconds 500
}
```