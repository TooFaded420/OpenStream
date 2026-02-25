param()
$ErrorActionPreference = 'Stop'

$pluginPath = "$env:APPDATA\Elgato\StreamDeck\Plugins\com.openclaw.streamdeck.v5.sdPlugin"
$logPath = "$env:APPDATA\Elgato\StreamDeck\logs\StreamDeck.log"

$okPlugin = Test-Path $pluginPath
$okConnected = $false
if (Test-Path $logPath) {
  $okConnected = Select-String -Path $logPath -Pattern "Plugin 'com.openclaw.streamdeck.v5' connected" -SimpleMatch -Quiet
}

Write-Host "pluginInstalled: $okPlugin"
Write-Host "pluginConnected: $okConnected"
if (-not $okPlugin -or -not $okConnected) { exit 1 }
exit 0
