param(
  [string]$ReportPath = "$env:USERPROFILE\.openclaw\streamdeck-report-v1.json"
)
$ErrorActionPreference = 'Stop'

$mapPath = "$env:USERPROFILE\.openclaw\streamdeck-device-map.json"
if (-not (Test-Path $ReportPath)) { throw "Missing report: $ReportPath" }

$report = Get-Content $ReportPath -Raw | ConvertFrom-Json
$existing = @{}
if (Test-Path $mapPath) {
  try { $existing = Get-Content $mapPath -Raw | ConvertFrom-Json -AsHashtable } catch {}
}

$assigned = @()
foreach ($d in $report.devices) {
  $serial = $d.serial
  $role = $null
  if ($existing.ContainsKey($serial)) {
    $role = $existing[$serial].role
  } else {
    # default if unknown; user can override later
    $role = 'control'
  }
  $assigned += [pscustomobject]@{ serial = $serial; role = $role }
}

$out = @{}
foreach ($a in $assigned) {
  $out[$a.serial] = @{ role = $a.role; updatedAt = (Get-Date).ToString('o') }
}

$out | ConvertTo-Json -Depth 6 | Out-File -FilePath $mapPath -Encoding UTF8
Write-Host "Saved: $mapPath"
$assigned | Format-Table -AutoSize
