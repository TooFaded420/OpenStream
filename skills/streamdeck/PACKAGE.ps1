# Package Stream Deck Skill for Distribution

param([string]$OutputPath = ".")

Write-Host "Packaging Stream Deck Auto-Setup Skill..." -ForegroundColor Cyan

$SkillName = "streamdeck-auto"
$TempDir = "$env:TEMP\$SkillName-package"
$Version = "3.0.0"

# Clean temp
if (Test-Path $TempDir) {
    Remove-Item $TempDir -Recurse -Force
}
New-Item -ItemType Directory -Path $TempDir -Force | Out-Null

# Copy files
$files = @(
    "SKILL-REVISED.md",
    "ORCHESTRATOR.ps1",
    "SETUP.ps1",
    "BUTTON-LAYOUTS.json"
)

foreach ($file in $files) {
    $source = "$PSScriptRoot\$file"
    if (Test-Path $source) {
        Copy-Item $source $TempDir -Force
        Write-Host "  Added: $file" -ForegroundColor Gray
    }
}

# Copy modules
Copy-Item "$PSScriptRoot\MODULES" $TempDir -Recurse -Force

# Rename skill file
Rename-Item "$TempDir\SKILL-REVISED.md" "$TempDir\SKILL.md" -Force

# Create manifest
$manifest = @{
    name = "streamdeck-auto"
    version = $Version
    description = "Auto-setup Stream Deck with OpenClaw"
    author = "OpenClaw"
} | ConvertTo-Json

$manifest | Out-File "$TempDir\package.json" -Encoding UTF8

# Create .skill file
$skillFile = "$OutputPath\streamdeck-auto-$Version.skill"
if (Test-Path $skillFile) { Remove-Item $skillFile -Force }

Compress-Archive -Path "$TempDir\*" -DestinationPath $skillFile -Force

Write-Host ""
Write-Host "Package created: $skillFile" -ForegroundColor Green
Write-Host "Install with: openclaw skills install streamdeck-auto-$Version.skill"