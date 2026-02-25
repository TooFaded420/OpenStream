param()
$ErrorActionPreference = 'Stop'

$out = "$env:USERPROFILE\.openclaw\streamdeck-report-v1.json"
$devices = @()

# Use Stream Deck logs/runtime metadata as source-of-truth fallback
$log = "$env:APPDATA\Elgato\StreamDeck\logs\StreamDeck.json"
if (Test-Path $log) {
  $lines = Get-Content $log -Tail 400 -ErrorAction SilentlyContinue
  foreach ($l in $lines) {
    if ($l -match 'Device connected, id: .* serial number: ([^,]+),') {
      $serial = $Matches[1]
      if (-not ($devices | Where-Object { $_.serial -eq $serial })) {
        $devices += [pscustomobject]@{ serial = $serial; source = 'streamdeck-log' }
      }
    }
  }
}

# Enrich with known device hints from current session info when available
# (safe fallback: leave unknown fields null)
$report = [pscustomobject]@{
  timestamp = (Get-Date).ToString('o')
  devices = $devices
  count = $devices.Count
}

$report | ConvertTo-Json -Depth 6 | Out-File -FilePath $out -Encoding UTF8
Write-Host "Saved: $out"
Write-Host "Devices: $($devices.Count)"
