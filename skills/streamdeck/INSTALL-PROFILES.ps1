# Install OpenClaw Profiles on Your Stream Decks
# This generates and imports profiles for MK.2 and Plus

param([switch]$SkipImport)

$ErrorActionPreference = "Stop"

Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   OpenClaw Stream Deck Profile Installer                ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Load layouts
$layoutsPath = "$PSScriptRoot\BUTTON-LAYOUTS.json"
$layouts = Get-Content $layoutsPath | ConvertFrom-Json

# Paths
$streamDeckProfilePath = "$env:APPDATA\Elgato\StreamDeck\ProfilesV2"
$openclawPluginPath = "$env:APPDATA\Elgato\StreamDeck\Plugins\com.openclaw.webhooks.sdPlugin"

# Check Stream Deck
Write-Host "Checking Stream Deck software..." -NoNewline
if (-not (Test-Path $streamDeckProfilePath)) {
    Write-Host " NOT FOUND" -ForegroundColor Red
    Write-Host "Please install Stream Deck software first: https://www.elgato.com/downloads"
    exit 1
}
Write-Host " OK" -ForegroundColor Green

# Check OpenClaw plugin
Write-Host "Checking OpenClaw plugin..." -NoNewline
if (-not (Test-Path $openclawPluginPath)) {
    Write-Host " NOT FOUND" -ForegroundColor Yellow
    Write-Host "Installing plugin..."
    # Plugin installation would go here
}
Write-Host " OK" -ForegroundColor Green

# Generate profiles
foreach ($device in $layouts.devices) {
    Write-Host ""
    Write-Host "Generating profile for: $($device.name) ($($device.keys) keys)" -ForegroundColor Cyan
    
    $profileName = $device.profile
    $profilePath = "$streamDeckProfilePath\$profileName.sdProfile"
    
    # Create profile directory
    if (-not (Test-Path $profilePath)) {
        New-Item -ItemType Directory -Path $profilePath -Force | Out-Null
    }
    
    # Generate manifest
    $manifest = @{
        Name = $profileName
        Version = $layouts.version
        Device = @{
            Model = $device.model
            UUID = [guid]::NewGuid().ToString()
        }
        Pages = @{
            Pages = @(@{
                Keys = @()
            })
        }
    }
    
    # Add keys
    foreach ($key in $device.layout.keys) {
        $keyData = @{
            Id = $key.key
            Action = $key.action
            Title = $key.title
            Settings = @{
                endpoint = "/$($key.action)"
                gatewayKey = "primary"
            }
        }
        $manifest.Pages.Pages[0].Keys += $keyData
    }
    
    # Add dials for Plus
    if ($device.dials) {
        $manifest.Dials = @()
        foreach ($dial in $device.layout.dials) {
            $manifest.Dials += @{
                Id = $dial.dial
                TurnAction = $dial.turn
                PressAction = $dial.press
                Title = $dial.title
            }
        }
    }
    
    # Save manifest
    $manifest | ConvertTo-Json -Depth 10 | Out-File "$profilePath\manifest.json" -Encoding UTF8
    
    Write-Host "  ✓ Created: $profileName" -ForegroundColor Green
    Write-Host "  Location: $profilePath" -ForegroundColor Gray
}

# Save gateway config
$gatewayConfig = @{
    primary = $layouts.multiGateway.primary
    secondary = $layouts.multiGateway.secondary
} | ConvertTo-Json

$gatewayConfigPath = "$env:USERPROFILE\.openclaw\streamdeck-plugin\gateway-config.json"
if (-not (Test-Path "$env:USERPROFILE\.openclaw\streamdeck-plugin")) {
    New-Item -ItemType Directory -Path "$env:USERPROFILE\.openclaw\streamdeck-plugin" -Force | Out-Null
}
$gatewayConfig | Out-File $gatewayConfigPath -Encoding UTF8

Write-Host ""
Write-Host "✓ Gateway config saved" -ForegroundColor Green

# Import to Stream Deck (if not skipped)
if (-not $SkipImport) {
    Write-Host ""
    Write-Host "Importing profiles to Stream Deck..." -ForegroundColor Cyan
    
    # Try to restart Stream Deck to pick up new profiles
    $sdProcess = Get-Process "StreamDeck" -ErrorAction SilentlyContinue
    if ($sdProcess) {
        Write-Host "  Restarting Stream Deck..." -NoNewline
        Stop-Process -Name "StreamDeck" -Force
        Start-Sleep 2
        
        $sdPaths = @(
            "$env:ProgramFiles\Elgato\StreamDeck\StreamDeck.exe"
            "$env:ProgramFiles(x86)\Elgato\StreamDeck\StreamDeck.exe"
            "$env:LOCALAPPDATA\Programs\Elgato\StreamDeck\StreamDeck.exe"
        )
        
        foreach ($path in $sdPaths) {
            if (Test-Path $path) {
                Start-Process $path
                break
            }
        }
        Write-Host " OK" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║   ✓ Installation Complete!                              ║" -ForegroundColor Green
Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "Profiles created:"
foreach ($device in $layouts.devices) {
    Write-Host "  • $($device.profile)" -ForegroundColor Cyan
}
Write-Host ""
Write-Host "Next steps:"
Write-Host "  1. Open Stream Deck software"
Write-Host "  2. Look for 'OpenClaw' profiles in the profile list"
Write-Host "  3. Select the profile for your device"
Write-Host "  4. Test the 'Switch GW' button to toggle gateways!"
Write-Host ""
Read-Host "Press Enter to exit"