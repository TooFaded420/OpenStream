param([switch]$Force)
$ErrorActionPreference = 'Stop'

$src = "$env:USERPROFILE\.openclaw\workspace\skills\streamdeck\plugin-v5-sdk"
$dst = "$env:APPDATA\Elgato\StreamDeck\Plugins\com.openclaw.streamdeck.v5.sdPlugin"

if (-not (Test-Path $src)) { throw "Source missing: $src" }
if ((Test-Path $dst) -and -not $Force) { Write-Host "Already installed. Use -Force."; exit 0 }
if (Test-Path $dst) { Remove-Item -Recurse -Force $dst }
Copy-Item -Recurse $src $dst
Write-Host "Installed: $dst"
