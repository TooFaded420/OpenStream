# Activate OpenClaw Profile in Stream Deck
# This script makes the profile visible in Stream Deck app

Write-Host "Activating OpenClaw Profile..." -ForegroundColor Cyan

$ProfileDir = "$env:APPDATA\Elgato\StreamDeck\ProfilesV2"
$SourceProfile = "$ProfileDir\OpenClaw-Control-MK2.sdProfile"

if (-not (Test-Path $SourceProfile)) {
    Write-Host "ERROR: Profile not found at $SourceProfile" -ForegroundColor Red
    exit 1
}

# Method 1: Create a copy with "Active" in name (sometimes helps detection)
$ActiveProfile = "$ProfileDir\OpenClaw-Active-MK2.sdProfile"
if (Test-Path $ActiveProfile) {
    Remove-Item $ActiveProfile -Recurse -Force
}
Copy-Item $SourceProfile $ActiveProfile -Recurse

# Method 2: Modify the manifest to make it more visible
$manifestPath = "$ActiveProfile\manifest.json"
if (Test-Path $manifestPath) {
    $manifest = Get-Content $manifestPath | ConvertFrom-Json
    $manifest.Name = "OpenClaw Active (CLICK ME)"
    $manifest | ConvertTo-Json -Depth 10 | Out-File $manifestPath -Encoding UTF8
}

# Restart Stream Deck
$sdProcess = Get-Process "StreamDeck" -ErrorAction SilentlyContinue
if ($sdProcess) {
    Write-Host "Restarting Stream Deck..." -ForegroundColor Yellow
    Stop-Process -Name "StreamDeck" -Force
    Start-Sleep 2
    
    $sdPath = "$env:ProgramFiles\Elgato\StreamDeck\StreamDeck.exe"
    if (Test-Path $sdPath) {
        Start-Process $sdPath
    }
}

Write-Host ""
Write-Host "================================" -ForegroundColor Green
Write-Host "Profile Activated!" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Green
Write-Host ""
Write-Host "Now in Stream Deck:" -ForegroundColor White
Write-Host "1. Look for 'OpenClaw Active (CLICK ME)' in profile dropdown" -ForegroundColor Yellow
Write-Host "2. Click it to select" -ForegroundColor Yellow
Write-Host "3. You should see the buttons!" -ForegroundColor Yellow
Write-Host ""
Read-Host "Press Enter to exit"