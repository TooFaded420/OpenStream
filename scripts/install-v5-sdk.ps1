param(
    [switch]$Force,
    [switch]$NoRestart,
    [switch]$ClearCache
)

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path $PSScriptRoot -Parent
$src = Join-Path $repoRoot 'plugin-v5-sdk'
$dst = "$env:APPDATA\Elgato\StreamDeck\Plugins\com.openclaw.streamdeck.v5.sdPlugin"
$streamDeckExe = 'C:\Program Files\Elgato\StreamDeck\StreamDeck.exe'
$gatewayCfg = "$env:USERPROFILE\.openclaw\streamdeck-gateways.json"
$cacheRoot = "$env:APPDATA\Elgato\StreamDeck\Cache"

function Write-Step([string]$msg) {
    Write-Host "[openclaw-v5] $msg" -ForegroundColor Cyan
}

function Ensure-GatewayConfig {
    $cfgDir = Split-Path $gatewayCfg -Parent
    if (-not (Test-Path $cfgDir)) {
        New-Item -ItemType Directory -Path $cfgDir -Force | Out-Null
    }

    if (Test-Path $gatewayCfg) {
        try {
            $cfg = Get-Content $gatewayCfg -Raw | ConvertFrom-Json
        } catch {
            $cfg = $null
        }
    } else {
        $cfg = $null
    }

    if (-not $cfg) {
        $cfg = [ordered]@{
            active = 'origin-main'
            gateways = [ordered]@{
                'origin-main' = [ordered]@{ url = 'http://127.0.0.1:18790'; token = $null }
            }
        }
    }

    if (-not $cfg.routeRoles) {
        $cfg | Add-Member -NotePropertyName routeRoles -NotePropertyValue ([ordered]@{})
    }

    $keys = @($cfg.gateways.PSObject.Properties.Name)
    $fallback = if ($keys -contains $cfg.active) { $cfg.active } elseif ($keys.Count -gt 0) { $keys[0] } else { 'origin-main' }
    if ($keys.Count -eq 0) {
        $cfg.gateways = [ordered]@{ 'origin-main' = [ordered]@{ url = 'http://127.0.0.1:18790'; token = $null } }
        $fallback = 'origin-main'
        $cfg.active = $fallback
        $keys = @($cfg.gateways.PSObject.Properties.Name)
    }

    foreach ($role in @('default', 'audio', 'research', 'agents', 'session', 'nodes')) {
        if (-not $cfg.routeRoles.$role -or -not ($keys -contains $cfg.routeRoles.$role)) {
            $cfg.routeRoles.$role = $fallback
        }
    }

    $cfg | ConvertTo-Json -Depth 12 | Set-Content -Path $gatewayCfg -Encoding UTF8
    Write-Step "Gateway config ready: $gatewayCfg"
}

function Clear-StreamDeckPluginCache {
    if (-not (Test-Path $cacheRoot)) {
        Write-Step "No Stream Deck cache directory found; skipping cache clear."
        return
    }

    Write-Step "Clearing Stream Deck plugin cache entries for OpenClaw"
    $patterns = @('*openclaw*', '*com.openclaw*')
    $targets = Get-ChildItem -Path $cacheRoot -Recurse -Force -ErrorAction SilentlyContinue |
        Where-Object {
            foreach ($p in $patterns) {
                if ($_.FullName -like $p) { return $true }
            }
            return $false
        } |
        Sort-Object FullName -Unique

    foreach ($target in $targets) {
        if (Test-Path $target.FullName) {
            Remove-Item -Recurse -Force $target.FullName -ErrorAction SilentlyContinue
        }
    }
}

if (-not (Test-Path $src)) { throw "Source missing: $src" }
if ((Test-Path $dst) -and -not $Force) {
    Write-Host "Already installed. Use -Force to reinstall." -ForegroundColor Yellow
    Ensure-GatewayConfig
    exit 0
}

Write-Step "Stopping Stream Deck process (if running)"
Get-Process StreamDeck -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Milliseconds 500

if (Test-Path $dst) {
    Write-Step "Removing existing plugin directory"
    Remove-Item -Recurse -Force $dst
}

Write-Step "Installing plugin files"
New-Item -ItemType Directory -Path $dst -Force | Out-Null
Copy-Item -Path (Join-Path $src '*') -Destination $dst -Recurse -Force
Write-Step "Installed: $dst"

Ensure-GatewayConfig

if ($ClearCache -or $Force) {
    Clear-StreamDeckPluginCache
}

if (-not $NoRestart -and (Test-Path $streamDeckExe)) {
    Write-Step "Starting Stream Deck"
    Start-Process $streamDeckExe | Out-Null
}

Write-Host "OpenClaw SDK v5 install complete." -ForegroundColor Green
