# Auto-Import OpenClaw Profiles to Stream Deck

$SourceProfiles = "$env:USERPROFILE\.openclaw\streamdeck-profiles"
$SourceIcons = "$env:USERPROFILE\.openclaw\workspace\skills\streamdeck\assets\icons"
$StreamDeckProfiles = "$env:APPDATA\Elgato\StreamDeck\ProfilesV2"

Write-Host "Auto-Importing OpenClaw Profiles..." -ForegroundColor Cyan
Write-Host ""

# Check Stream Deck
if (-not (Test-Path $StreamDeckProfiles)) {
    Write-Host "ERROR: Stream Deck not found!" -ForegroundColor Red
    exit 1
}

# Get profiles
$profiles = Get-ChildItem $SourceProfiles -Filter "OpenClaw-*.sdProfile" | Where-Object { $_.Name -notmatch '-\d+\.' }
Write-Host "Found $($profiles.Count) profiles to import:" -ForegroundColor Yellow
$profiles | ForEach-Object { Write-Host "  $($_.Name)" }
Write-Host ""

# Import each
$imported = 0
foreach ($profile in $profiles) {
    $target = Join-Path $StreamDeckProfiles $profile.Name
    
    if (Test-Path $target) {
        Write-Host "Already exists: $($profile.Name)" -ForegroundColor Yellow
        continue
    }
    
    Write-Host "Importing: $($profile.Name)..." -NoNewline
    Copy-Item $profile.FullName $target -Recurse
    
    # Copy icons
    $images = Join-Path $target "Images"
    New-Item -ItemType Directory -Path $images -Force | Out-Null
    Get-ChildItem $SourceIcons -Filter "*.png" | Copy-Item -Destination $images
    
    Write-Host " DONE" -ForegroundColor Green
    $imported++
}

Write-Host ""
Write-Host "Imported: $imported profiles" -ForegroundColor Green
Write-Host ""

# Show what's now in Stream Deck
Write-Host "Profiles now in Stream Deck:" -ForegroundColor Cyan
Get-ChildItem $StreamDeckProfiles -Filter "OpenClaw-*.sdProfile" | Where-Object { $_.Name -notmatch '-\d+\.' } | ForEach-Object {
    $m = Get-Content "$($_.FullName)\manifest.json" | ConvertFrom-Json
    Write-Host "  $($m.Name)" -ForegroundColor White
}

Write-Host ""
Write-Host "Restart Stream Deck software to see the profiles!" -ForegroundColor Yellow
