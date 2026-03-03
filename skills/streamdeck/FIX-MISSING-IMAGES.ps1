# Fix Missing Profile Images

Write-Host "Creating missing profile images..." -ForegroundColor Cyan

$Profiles = @(
    "OpenClaw-Control-MK2.sdProfile",
    "OpenClaw-Studio-Plus.sdProfile"
)

$ProfileDir = "$env:APPDATA\Elgato\StreamDeck\ProfilesV2"

foreach ($profile in $Profiles) {
    $profilePath = "$ProfileDir\$profile"
    
    if (Test-Path $profilePath) {
        Write-Host "Processing: $profile" -ForegroundColor Gray
        
        # Create Images folder
        $imagesPath = "$profilePath\Images"
        if (-not (Test-Path $imagesPath)) {
            New-Item -ItemType Directory -Path $imagesPath -Force | Out-Null
        }
        
        # Create placeholder icons
        @("actionIcon", "actionIcon@2x", "categoryIcon", "categoryIcon@2x") | ForEach-Object {
            $iconFile = "$imagesPath\$_.png"
            if (-not (Test-Path $iconFile)) {
                "PNG placeholder" | Out-File $iconFile -Encoding UTF8
            }
        }
        
        Write-Host "  Created images folder" -ForegroundColor Green
    }
}

# Copy from assets if available
$AssetsPath = "$PSScriptRoot\assets\icons"
if (Test-Path $AssetsPath) {
    Get-ChildItem $AssetsPath -Filter "*.png" | ForEach-Object {
        foreach ($profile in $Profiles) {
            $dest = "$ProfileDir\$profile\Images\$($_.Name)"
            Copy-Item $_.FullName $dest -Force
        }
    }
    Write-Host "Copied icons from assets" -ForegroundColor Green
}

Write-Host ""
Write-Host "Image fix complete!" -ForegroundColor Green
Write-Host "Restart Stream Deck to see changes" -ForegroundColor Yellow