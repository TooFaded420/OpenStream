param([int]$Port = 8787)
$ErrorActionPreference = 'Stop'

$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$IndexPath = Join-Path $Root 'index.html'
$WizardPath = Join-Path $Root 'wizard.html'
$DeviceMapPath = "$env:USERPROFILE\.openclaw\streamdeck-device-map.json"
$GatewayCfgPath = "$env:USERPROFILE\.openclaw\streamdeck-gateways.json"

function Get-DefaultGatewayCfg {
  return [ordered]@{
    active = 'origin-main'
    gateways = [ordered]@{
      'origin-main' = [ordered]@{ url = 'http://127.0.0.1:18790'; token = $null }
    }
  }
}

function Normalize-GatewayCfg($obj) {
  $cfg = Get-DefaultGatewayCfg
  if (-not $obj) { return $cfg }

  if ($obj.active) { $cfg.active = [string]$obj.active }

  $cfg.gateways = [ordered]@{}
  $gws = $obj.gateways
  if ($gws) {
    foreach ($p in $gws.PSObject.Properties) {
      $name = [string]$p.Name
      $val = $p.Value
      $url = if ($val.url) { [string]$val.url } else { 'http://127.0.0.1:18790' }
      $token = if ($null -eq $val.token -or "$($val.token)" -eq '') { $null } else { [string]$val.token }
      $cfg.gateways[$name] = [ordered]@{ url = $url; token = $token }
    }
  }

  if ($cfg.gateways.Count -eq 0) {
    $cfg = Get-DefaultGatewayCfg
  }

  if (-not $cfg.gateways.Contains($cfg.active)) {
    $cfg.active = ($cfg.gateways.Keys | Select-Object -First 1)
  }

  return $cfg
}

function Load-GatewayCfg {
  if (Test-Path $GatewayCfgPath) {
    try {
      $raw = Get-Content $GatewayCfgPath -Raw
      $obj = $raw | ConvertFrom-Json
      return (Normalize-GatewayCfg $obj)
    } catch {}
  }
  return (Get-DefaultGatewayCfg)
}

function Save-GatewayCfg($cfg) {
  $safe = Normalize-GatewayCfg $cfg
  $safe | ConvertTo-Json -Depth 8 | Out-File -FilePath $GatewayCfgPath -Encoding UTF8
}

function Test-Gateway([string]$url) {
  try {
    Invoke-RestMethod -Uri "$url/status" -Method Get -TimeoutSec 2 | Out-Null
    return $true
  } catch { return $false }
}

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$Port/")
$listener.Prefixes.Add("http://127.0.0.1:$Port/")
$listener.Start()
Write-Host "OpenClaw Dashboard server running on http://localhost:$Port" -ForegroundColor Green

try {
  while ($listener.IsListening) {
    $ctx = $listener.GetContext(); $req = $ctx.Request; $res = $ctx.Response
    try {
      switch -Regex ($req.Url.AbsolutePath) {
        '^/$|^/index.html$' {
          $bytes = [Text.Encoding]::UTF8.GetBytes((Get-Content $IndexPath -Raw))
          $res.ContentType='text/html; charset=utf-8'; $res.StatusCode=200
          $res.OutputStream.Write($bytes,0,$bytes.Length)
        }
        '^/wizard$|^/wizard.html$' {
          $bytes = [Text.Encoding]::UTF8.GetBytes((Get-Content $WizardPath -Raw))
          $res.ContentType='text/html; charset=utf-8'; $res.StatusCode=200
          $res.OutputStream.Write($bytes,0,$bytes.Length)
        }
        '^/api/device-map$' {
          $payload = if (Test-Path $DeviceMapPath) { Get-Content $DeviceMapPath -Raw } else { '{}' }
          $bytes = [Text.Encoding]::UTF8.GetBytes($payload)
          $res.ContentType='application/json; charset=utf-8'; $res.StatusCode=200
          $res.OutputStream.Write($bytes,0,$bytes.Length)
        }
        '^/api/gateway-config$' {
          if ($req.HttpMethod -eq 'POST') {
            $sr = New-Object IO.StreamReader($req.InputStream, $req.ContentEncoding)
            $body = $sr.ReadToEnd(); $sr.Close()
            $obj = $body | ConvertFrom-Json
            Save-GatewayCfg $obj
          }
          $payload = (Load-GatewayCfg | ConvertTo-Json -Depth 8)
          $bytes = [Text.Encoding]::UTF8.GetBytes($payload)
          $res.ContentType='application/json; charset=utf-8'; $res.StatusCode=200
          $res.OutputStream.Write($bytes,0,$bytes.Length)
        }
        '^/api/detect-local$' {
          $cfg = Load-GatewayCfg
          $ports = @('18790','18789','28790')
          if ($req.HttpMethod -eq 'POST') {
            $sr = New-Object IO.StreamReader($req.InputStream, $req.ContentEncoding)
            $body = $sr.ReadToEnd(); $sr.Close()
            if ($body) {
              try {
                $obj = $body | ConvertFrom-Json
                if ($obj.ports) { $ports = @($obj.ports) }
              } catch {}
            }
          }

          $gws = [ordered]@{}
          foreach ($p in $ports) {
            $url = "http://127.0.0.1:$p"
            if (Test-Gateway $url) {
              $name = switch ($p) { '18790' {'origin-main'} '18789' {'zero-mac'} default {"local-$p"} }
              $token = $null
              if ($cfg.gateways.Contains($name)) { $token = $cfg.gateways[$name].token }
              $gws[$name] = [ordered]@{ url = $url; token = $token }
            }
          }
          foreach ($k in $cfg.gateways.Keys) { if (-not $gws.Contains($k)) { $gws[$k] = $cfg.gateways[$k] } }
          $cfg.gateways = $gws
          if (-not $cfg.gateways.Contains($cfg.active)) { $cfg.active = ($cfg.gateways.Keys | Select-Object -First 1) }
          Save-GatewayCfg $cfg

          $payload = ($cfg | ConvertTo-Json -Depth 8)
          $bytes = [Text.Encoding]::UTF8.GetBytes($payload)
          $res.ContentType='application/json; charset=utf-8'; $res.StatusCode=200
          $res.OutputStream.Write($bytes,0,$bytes.Length)
        }
        '^/api/test-gateways$' {
          $cfg = Load-GatewayCfg
          $out = [ordered]@{}
          foreach ($k in $cfg.gateways.Keys) {
            $g = $cfg.gateways[$k]
            $sw = [Diagnostics.Stopwatch]::StartNew()
            try {
              $headers = @{}
              if ($g.token) { $headers['Authorization'] = "Bearer $($g.token)" }
              Invoke-RestMethod -Uri "$($g.url)/status" -Method Get -Headers $headers -TimeoutSec 3 | Out-Null
              $sw.Stop()
              $out[$k] = [ordered]@{ ok = $true; latencyMs = [int]$sw.ElapsedMilliseconds; code = 'OK' }
            } catch {
              $sw.Stop()
              $msg = "$($_.Exception.Message)".ToLower()
              $code = if ($msg -match '401|403|unauthorized|forbidden') { 'AUTH' } elseif ($msg -match 'timed out|timeout|abort') { 'TIME' } else { 'OFF' }
              $out[$k] = [ordered]@{ ok = $false; latencyMs = $null; code = $code }
            }
          }
          $payload = ($out | ConvertTo-Json -Depth 6)
          $bytes = [Text.Encoding]::UTF8.GetBytes($payload)
          $res.ContentType='application/json; charset=utf-8'; $res.StatusCode=200
          $res.OutputStream.Write($bytes,0,$bytes.Length)
        }
        '^/api/apply-best-gateway$' {
          $cfg = Load-GatewayCfg
          $best = $null
          foreach ($k in $cfg.gateways.Keys) {
            $g = $cfg.gateways[$k]
            $sw = [Diagnostics.Stopwatch]::StartNew()
            try {
              $headers = @{}
              if ($g.token) { $headers['Authorization'] = "Bearer $($g.token)" }
              Invoke-RestMethod -Uri "$($g.url)/status" -Method Get -Headers $headers -TimeoutSec 3 | Out-Null
              $sw.Stop(); $lat = [int]$sw.ElapsedMilliseconds
              if (-not $best -or $lat -lt $best.latencyMs) { $best = [ordered]@{ key = $k; latencyMs = $lat } }
            } catch { $sw.Stop() }
          }
          if ($best) {
            $cfg.active = $best.key
            Save-GatewayCfg $cfg
            $payload = (@{ ok = $true; active = $best.key; latencyMs = $best.latencyMs } | ConvertTo-Json)
          } else {
            $payload = (@{ ok = $false; error = 'No healthy gateways found' } | ConvertTo-Json)
          }
          $bytes = [Text.Encoding]::UTF8.GetBytes($payload)
          $res.ContentType='application/json; charset=utf-8'; $res.StatusCode=200
          $res.OutputStream.Write($bytes,0,$bytes.Length)
        }
        default {
          $res.StatusCode = 404
          $bytes = [Text.Encoding]::UTF8.GetBytes('Not Found')
          $res.OutputStream.Write($bytes,0,$bytes.Length)
        }
      }
    } finally { $res.OutputStream.Close() }
  }
}
finally { $listener.Stop() }
