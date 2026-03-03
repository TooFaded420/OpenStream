param(
    [switch]$Overwrite
)

$ErrorActionPreference = 'Stop'

function Write-Step([string]$msg) {
    Write-Host "[plus-profile] $msg" -ForegroundColor Cyan
}

$profileRoot = "$env:APPDATA\Elgato\StreamDeck\ProfilesV2\OpenClaw-Plus-v5.sdProfile"
$profilesDir = Join-Path $profileRoot 'Profiles'
$imagesDir = Join-Path $profileRoot 'Images'
$pageIdKeys = [Guid]::NewGuid().ToString()
$pageIdDials = [Guid]::NewGuid().ToString()

if ((Test-Path $profileRoot) -and -not $Overwrite) {
    Write-Host "Profile already exists. Use -Overwrite to regenerate." -ForegroundColor Yellow
    exit 0
}

Write-Step "Stopping Stream Deck process (if running)"
Get-Process StreamDeck -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Milliseconds 500

if (Test-Path $profileRoot) {
    Remove-Item -Recurse -Force $profileRoot
}

New-Item -ItemType Directory -Path $profilesDir -Force | Out-Null
New-Item -ItemType Directory -Path $imagesDir -Force | Out-Null

$manifest = [ordered]@{
    Device = [ordered]@{
        Model = '20GBA9901'
        UUID = '@(1)[AUTO/OPENCLAW/PLUSV5]'
    }
    Name = 'OpenClaw Plus v5'
    Pages = [ordered]@{
        Current = $pageIdKeys
        Default = $pageIdKeys
        Pages = @($pageIdKeys, $pageIdDials)
    }
    Version = '2.0'
}
$manifest | ConvertTo-Json -Depth 8 | Set-Content (Join-Path $profileRoot 'manifest.json') -Encoding UTF8

$keysActions = @(
    # First 8 actions are the visible Plus layout defaults (4x2).
    @{ Key = 0; UUID = 'com.openclaw.v5.status'; Name = 'Status' }
    @{ Key = 1; UUID = 'com.openclaw.v5.spawn'; Name = 'Spawn' }
    @{ Key = 2; UUID = 'com.openclaw.v5.websearch'; Name = 'Search' }
    @{ Key = 3; UUID = 'com.openclaw.v5.session'; Name = 'Session' }
    @{ Key = 4; UUID = 'com.openclaw.v5.subagents'; Name = 'Agents' }
    @{ Key = 5; UUID = 'com.openclaw.v5.nodes'; Name = 'Nodes' }
    @{ Key = 6; UUID = 'com.openclaw.v5.gateway.next'; Name = 'Next' }
    @{ Key = 7; UUID = 'com.openclaw.v5.setup.wizard'; Name = 'Wizard' }
    # Advanced keys for larger decks/pages.
    @{ Key = 8; UUID = 'com.openclaw.v5.route.mode'; Name = 'Route' }
    @{ Key = 9; UUID = 'com.openclaw.v5.route.gateway'; Name = 'Target' }
    @{ Key = 10; UUID = 'com.openclaw.v5.route.health'; Name = 'Best' }
    @{ Key = 11; UUID = 'com.openclaw.v5.tts'; Name = 'TTS' }
)

$keysPage = [ordered]@{
    Controller = ''
    Actions = @(
        foreach ($a in $keysActions) {
            [ordered]@{
                Key = $a.Key
                UUID = $a.UUID
                Name = $a.Name
                States = @(@{
                    Title = $a.Name
                })
                Settings = @{}
            }
        }
    )
}
$keysPage | ConvertTo-Json -Depth 12 | Set-Content (Join-Path $profilesDir "$pageIdKeys.json") -Encoding UTF8

$dialActions = @(
    @{ Key = 0; UUID = 'com.openclaw.streamdeck.v5.dial.model'; Name = 'Model' }
    @{ Key = 1; UUID = 'com.openclaw.streamdeck.v5.dial.tts'; Name = 'TTS' }
    @{ Key = 2; UUID = 'com.openclaw.streamdeck.v5.dial.agents'; Name = 'Agents' }
    @{ Key = 3; UUID = 'com.openclaw.streamdeck.v5.dial.profile'; Name = 'Gateway' }
)

$dialPage = [ordered]@{
    Controller = 'Encoder'
    Actions = @(
        foreach ($a in $dialActions) {
            [ordered]@{
                Key = $a.Key
                UUID = $a.UUID
                Name = $a.Name
                States = @(@{
                    Title = $a.Name
                })
                Settings = @{}
            }
        }
    )
}
$dialPage | ConvertTo-Json -Depth 12 | Set-Content (Join-Path $profilesDir "$pageIdDials.json") -Encoding UTF8

Write-Step "Profile installed: $profileRoot"

$streamDeckExe = 'C:\Program Files\Elgato\StreamDeck\StreamDeck.exe'
if (Test-Path $streamDeckExe) {
    Write-Step "Restarting Stream Deck"
    Start-Process $streamDeckExe | Out-Null
}

Write-Host "OpenClaw Plus starter profile created. In Stream Deck, switch to profile: OpenClaw Plus v5" -ForegroundColor Green
