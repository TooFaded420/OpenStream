param(
  [string[]]$Ports = @('18790','28790','38790'),
  [string]$GatewayHost = '127.0.0.1',
  [switch]$IncludeLanCandidates
)

$ErrorActionPreference = 'Stop'
$configPath = "$env:USERPROFILE\.openclaw\streamdeck-gateways.json"

function Test-Gateway([string]$url) {
  try {
    $res = Invoke-RestMethod -Uri "$url/status" -Method Get -TimeoutSec 2
    $m = if ($res.model) { $res.model } else { 'unknown' }
    return @{ ok = $true; model = $m }
  } catch {
    return @{ ok = $false }
  }
}

# load existing config if present
$cfg = $null
if (Test-Path $configPath) {
  try { $cfg = Get-Content $configPath -Raw | ConvertFrom-Json } catch { $cfg = $null }
}
if (-not $cfg) {
  $cfg = [pscustomobject]@{ active = 'origin-main'; gateways = [ordered]@{} }
}
if (-not $cfg.gateways) { $cfg | Add-Member -NotePropertyName gateways -NotePropertyValue ([ordered]@{}) }

# preserve existing entries/tokens
$existing = @{}
$cfg.gateways.PSObject.Properties | ForEach-Object { $existing[$_.Name] = $_.Value }

$detected = [ordered]@{}
foreach ($p in $Ports) {
  $url = "http://$GatewayHost`:$p"
  $t = Test-Gateway $url
  if ($t.ok) {
    $name = switch ($p) {
      '18790' { 'origin-main' }
      '28790' { 'origin-alt' }
      default { "local-$p" }
    }
    $token = $null
    if ($existing.ContainsKey($name) -and $existing[$name].token) { $token = $existing[$name].token }
    $detected[$name] = [pscustomobject]@{ url = $url; token = $token }
    Write-Host "Detected gateway: $name -> $url"
  }
}

if ($IncludeLanCandidates) {
  # Add placeholders for future remote/phone endpoints if not present
  if (-not $detected.Contains('phone-soon')) {
    $token = $null
    if ($existing.ContainsKey('phone-soon') -and $existing['phone-soon'].token) { $token = $existing['phone-soon'].token }
    $detected['phone-soon'] = [pscustomobject]@{ url = 'http://100.100.100.100:18790'; token = $token }
  }
}

if ($detected.Count -eq 0) {
  Write-Host 'No local gateways detected on scanned ports.'
  exit 0
}

# merge with existing non-local entries
foreach ($k in $existing.Keys) {
  if (-not $detected.Contains($k)) { $detected[$k] = $existing[$k] }
}

$cfg.gateways = $detected
$gatewayNames = @()
if ($cfg.gateways -is [System.Collections.IDictionary]) {
  $gatewayNames = @($cfg.gateways.Keys)
} else {
  $gatewayNames = @($cfg.gateways.PSObject.Properties | Where-Object { $_.MemberType -eq 'NoteProperty' } | ForEach-Object { $_.Name })
}
if (-not $cfg.active -or -not ($gatewayNames -contains $cfg.active)) {
  $cfg.active = ($gatewayNames | Select-Object -First 1)
}

$cfg | ConvertTo-Json -Depth 8 | Out-File -FilePath $configPath -Encoding UTF8
Write-Host "Saved: $configPath"
Write-Host "Active gateway: $($cfg.active)"
