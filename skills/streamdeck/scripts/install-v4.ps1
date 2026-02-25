# Install OpenClaw Live v4 Plugin
param([switch]$Force)

$ErrorActionPreference = 'Stop'

$pluginSource = "$env:USERPROFILE\.openclaw\workspace\skills\streamdeck\plugin-v4"
$pluginDest = "$env:APPDATA\Elgato\StreamDeck\Plugins\com.openclaw.streamdeck.v4.sdPlugin"

Write-Host "Installing OpenClaw Live v4..." -ForegroundColor Cyan

if (-not (Test-Path $pluginSource)) {
    Write-Error "Plugin source not found: $pluginSource"
    exit 1
}

if (Test-Path $pluginDest) {
    if (-not $Force) {
        Write-Host "Plugin already installed. Use -Force to reinstall." -ForegroundColor Yellow
        exit 0
    }

    Write-Host "Removing existing installation..." -ForegroundColor Yellow
    Remove-Item -Recurse -Force $pluginDest
}

Write-Host "Copying plugin files..." -ForegroundColor Gray
Copy-Item -Recurse $pluginSource $pluginDest

if (-not (Test-Path "$pluginDest\manifest.json")) {
    Write-Error "Installation failed: manifest.json not found at destination"
    exit 1
}

$iconCount = (Get-ChildItem "$pluginDest\images" -Filter "*.png" -ErrorAction SilentlyContinue).Count
Write-Host "Install complete." -ForegroundColor Green
Write-Host "Location: $pluginDest" -ForegroundColor Gray
Write-Host "PNG icons: $iconCount" -ForegroundColor Gray

Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1) Restart Stream Deck" -ForegroundColor White
Write-Host "2) Look for category: OpenClaw Live" -ForegroundColor White
Write-Host "3) Drag actions to keys" -ForegroundColor White
