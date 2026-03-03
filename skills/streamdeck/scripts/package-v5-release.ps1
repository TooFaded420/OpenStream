param(
    [string]$Version = '5.4.0',
    [string]$OutDir = "$PSScriptRoot\..\dist"
)

$ErrorActionPreference = 'Stop'

function Write-Step([string]$msg) {
    Write-Host "[package-v5] $msg" -ForegroundColor Cyan
}

$repoRoot = Split-Path $PSScriptRoot -Parent
$stage = Join-Path $env:TEMP "openclaw-streamdeck-v5-$Version"
$outDirResolved = Resolve-Path (Join-Path $repoRoot $OutDir.Replace("$PSScriptRoot\..\", "")) -ErrorAction SilentlyContinue
if (-not $outDirResolved) {
    $outDirResolved = Join-Path $repoRoot 'dist'
    New-Item -ItemType Directory -Path $outDirResolved -Force | Out-Null
} else {
    $outDirResolved = $outDirResolved.Path
}

$artifactName = "openclaw-streamdeck-v5-$Version.zip"
$artifactPath = Join-Path $outDirResolved $artifactName
$shaPath = Join-Path $outDirResolved "$artifactName.sha256.txt"

if (Test-Path $stage) { Remove-Item -Recurse -Force $stage }
New-Item -ItemType Directory -Path $stage -Force | Out-Null

Write-Step "Staging files"
New-Item -ItemType Directory -Path (Join-Path $stage 'plugin-v5-sdk') -Force | Out-Null
Copy-Item -Path (Join-Path $repoRoot 'plugin-v5-sdk\*') -Destination (Join-Path $stage 'plugin-v5-sdk') -Recurse -Force

New-Item -ItemType Directory -Path (Join-Path $stage 'web-dashboard') -Force | Out-Null
Copy-Item -Path (Join-Path $repoRoot 'web-dashboard\*') -Destination (Join-Path $stage 'web-dashboard') -Recurse -Force

New-Item -ItemType Directory -Path (Join-Path $stage 'scripts') -Force | Out-Null
Copy-Item -Path (Join-Path $repoRoot 'scripts\install-v5-sdk.ps1') -Destination (Join-Path $stage 'scripts') -Force

$readme = @"
# OpenClaw Stream Deck SDK v5

## Install (Windows)

1. Extract this archive.
2. Run PowerShell as your user and execute:

```powershell
.\scripts\install-v5-sdk.ps1 -Force
```

If Stream Deck does not show actions immediately, reinstall with cache refresh:

```powershell
.\scripts\install-v5-sdk.ps1 -Force -ClearCache
```

## Included

- plugin-v5-sdk: Stream Deck plugin runtime + actions + routing property inspector
- web-dashboard: gateway setup wizard/dashboard
- scripts/install-v5-sdk.ps1: robust installer

## Notes

- Restart Stream Deck after install if it was already open.
- Gateway config is stored at `%USERPROFILE%\.openclaw\streamdeck-gateways.json`.
"@
$readme | Set-Content -Path (Join-Path $stage 'README-INSTALL.md') -Encoding UTF8

if (Test-Path $artifactPath) { Remove-Item $artifactPath -Force }
Write-Step "Creating zip artifact"
Compress-Archive -Path (Join-Path $stage '*') -DestinationPath $artifactPath -Force

$hash = Get-FileHash $artifactPath -Algorithm SHA256
"$($hash.Hash)  $artifactName" | Set-Content -Path $shaPath -Encoding UTF8

Write-Step "Artifact ready: $artifactPath"
Write-Step "SHA256: $shaPath"
