# Simple Project Dashboard
$root = "$env:USERPROFILE\.openclaw\workspace\skills\streamdeck"

Write-Host ""
Write-Host "OpenClaw Stream Deck Plugin - Project Dashboard" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

# Stats
$files = (Get-ChildItem $root -Recurse -File).Count
$dirs = (Get-ChildItem $root -Recurse -Directory).Count

Write-Host "Files: $files | Folders: $dirs" -ForegroundColor Gray
Write-Host ""

# Menu
Write-Host "[1] Plugin v3 (Latest)" -ForegroundColor Green
Write-Host "[2] Scripts" -ForegroundColor Green
Write-Host "[3] Assets (Icons)" -ForegroundColor Green
Write-Host "[4] Documentation" -ForegroundColor Green
Write-Host "[5] Marketing" -ForegroundColor Green
Write-Host "[6] INDEX.md (Full Guide)" -ForegroundColor Yellow
Write-Host "[7] Open in VS Code" -ForegroundColor Magenta
Write-Host "[8] Open in Explorer" -ForegroundColor Magenta
Write-Host "[Q] Quit" -ForegroundColor Red
Write-Host ""

$choice = Read-Host "Select option"

switch ($choice) {
    "1" { explorer "$root\plugin-v3" }
    "2" { explorer "$root\scripts" }
    "3" { explorer "$root\assets" }
    "4" { explorer "$root" }
    "5" { explorer "$root\marketing" }
    "6" { Start-Process "$root\INDEX.md" }
    "7" { code $root }
    "8" { explorer $root }
    "Q" { exit }
}
