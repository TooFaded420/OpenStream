# OpenClaw Stream Deck - Fully Automated Setup
# One command, everything done automatically

param(
    [switch]$Diagnostics,
    [switch]$Uninstall,
    [switch]$Silent
)

$ErrorActionPreference = "Stop"

# Helper functions
function Write-Step {
    param($Number, $Total, $Message)
    if (-not $Silent) {
        Write-Host "[$Number/$Total] " -NoNewline -ForegroundColor Yellow
        Write-Host $Message -NoNewline
    }
}

function Write-Done {
    if (-not $Silent) { 
        Write-Host " OK" -ForegroundColor Green 
    }
}

function Write-ErrorLine {
    param($Message)
    if (-not $Silent) { Write-Host " ERROR: $Message" -ForegroundColor Red }
}

# Step 1: Detect Stream Deck Hardware
Write-Step 1 6 "Detecting Stream Deck hardware..."

$devices = @()
try {
    $regPaths = "HKLM:\SYSTEM\CurrentControlSet\Enum\USB\VID_0FD9*"
    if (Test-Path $regPaths) {
        $devices = Get-ChildItem $regPaths -ErrorAction SilentlyContinue
    }
} catch {}

$deviceCount = $devices.Count
if ($deviceCount -eq 0) {
    Write-ErrorLine "No Stream Deck hardware detected. Please connect your Stream Deck."
    exit 1
}
Write-Done
if (-not $Silent) { Write-Host "    Found $deviceCount device(s)" -ForegroundColor Gray }

# Step 2: Check Stream Deck Software
Write-Step 2 6 "Checking Stream Deck software..."

$sdPaths = @(
    "$env:ProgramFiles\Elgato\StreamDeck\StreamDeck.exe",
    "$env:LOCALAPPDATA\Programs\Elgato\StreamDeck\StreamDeck.exe"
)

$sdPath = $null
foreach ($path in $sdPaths) {
    if (Test-Path $path) {
        $sdPath = $path
        break
    }
}

if (-not $sdPath) {
    Write-ErrorLine "Stream Deck software not found!"
    if (-not $Silent) {
        Write-Host "    Please install from: https://www.elgato.com/downloads" -ForegroundColor Yellow
    }
    exit 1
}
Write-Done

# Step 3: Install OpenClaw Plugin
Write-Step 3 6 "Installing OpenClaw plugin..."

$pluginDir = "$env:APPDATA\Elgato\StreamDeck\Plugins\com.openclaw.webhooks.sdPlugin"
if (-not (Test-Path $pluginDir)) {
    New-Item -ItemType Directory -Path $pluginDir -Force | Out-Null
    
    $manifest = @{
        Name = "OpenClaw Webhooks"
        Version = "3.0.0"
        Author = "OpenClaw"
        Description = "Control OpenClaw AI from Stream Deck"
        URL = "https://openclaw.ai"
        Category = "OpenClaw"
        CodePath = "plugin.ps1"
        Actions = @(@{ Name = "OpenClaw Action"; UUID = "com.openclaw.webhooks.action" })
    } | ConvertTo-Json
    
    $manifest | Out-File "$pluginDir\manifest.json" -Encoding UTF8
}
Write-Done

# Step 4: Generate Profiles
Write-Step 4 6 "Generating optimized profiles..."

$profileDir = "$env:APPDATA\Elgato\StreamDeck\ProfilesV2"
$layoutsPath = "$PSScriptRoot\BUTTON-LAYOUTS.json"

if (Test-Path $layoutsPath) {
    $layouts = Get-Content $layoutsPath | ConvertFrom-Json
    
    foreach ($device in $layouts.devices) {
        $profileName = $device.profile
        $profilePath = "$profileDir\$profileName.sdProfile"
        
        if (-not (Test-Path $profilePath)) {
            New-Item -ItemType Directory -Path $profilePath -Force | Out-Null
            
            $manifest = @{
                Name = $profileName
                Version = "3.0.0"
                Device = @{ Model = $device.model; UUID = [guid]::NewGuid().ToString() }
                Pages = @{ Pages = @(@{ Keys = @() }) }
            }
            
            foreach ($key in $device.layout.keys) {
                $manifest.Pages.Pages[0].Keys += @{
                    Id = $key.key
                    Action = "com.openclaw.webhooks.action"
                    Title = $key.title
                    Settings = @{ endpoint = "/$($key.action)"; gatewayKey = "primary" }
                }
            }
            
            $manifest | ConvertTo-Json -Depth 10 | Out-File "$profilePath\manifest.json" -Encoding UTF8
        }
    }
}
Write-Done

# Step 5: Configure Multi-Gateway
Write-Step 5 6 "Configuring multi-gateway support..."

$configDir = "$env:USERPROFILE\.openclaw\streamdeck-plugin"
if (-not (Test-Path $configDir)) {
    New-Item -ItemType Directory -Path $configDir -Force | Out-Null
}

$gatewayConfig = @{
    primary = "http://127.0.0.1:18790"
    secondary = $null
} | ConvertTo-Json

$gatewayConfig | Out-File "$configDir\gateway-config.json" -Encoding UTF8
Write-Done

# Step 6: Restart Stream Deck
Write-Step 6 6 "Restarting Stream Deck..."

$sdProcess = Get-Process "StreamDeck" -ErrorAction SilentlyContinue
if ($sdProcess) {
    Stop-Process -Name "StreamDeck" -Force
    Start-Sleep 2
}

Start-Process $sdPath
Start-Sleep 5
Write-Done

# Final Summary
if (-not $Silent) {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "SETUP COMPLETE!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Your Stream Deck is now ready!" -ForegroundColor White
    Write-Host ""
    Write-Host "Available buttons:"
    Write-Host "  - Spawn Agent  - TTS Toggle  - Status Check"
    Write-Host "  - Models       - Switch GW   - Memory Search"
    Write-Host "  - Code Agent   - Debug Help  - Web Search"
    Write-Host ""
    Write-Host "Gateway switching:"
    Write-Host "  Press 'Switch GW' to toggle between gateways"
    Write-Host ""
    Write-Host "Next: Open Stream Deck and select OpenClaw profile!"
    Write-Host ""
    Read-Host "Press Enter to exit"
}

exit 0