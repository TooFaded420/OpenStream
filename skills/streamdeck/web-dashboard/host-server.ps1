param(
  [int]$Port = 8787
)

$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$IndexPath = Join-Path $Root 'index.html'
$DeviceMapPath = "$env:USERPROFILE\.openclaw\streamdeck-device-map.json"

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://+:$Port/")
$listener.Start()

Write-Host "OpenClaw Dashboard server running on http://localhost:$Port" -ForegroundColor Green

try {
  while ($listener.IsListening) {
    $ctx = $listener.GetContext()
    $req = $ctx.Request
    $res = $ctx.Response

    try {
      switch -Regex ($req.Url.AbsolutePath) {
        '^/$|^/index.html$' {
          $html = Get-Content $IndexPath -Raw
          $bytes = [System.Text.Encoding]::UTF8.GetBytes($html)
          $res.ContentType = 'text/html; charset=utf-8'
          $res.StatusCode = 200
          $res.OutputStream.Write($bytes, 0, $bytes.Length)
        }
        '^/api/device-map$' {
          $payload = if (Test-Path $DeviceMapPath) { Get-Content $DeviceMapPath -Raw } else { '{"devices":{}}' }
          $bytes = [System.Text.Encoding]::UTF8.GetBytes($payload)
          $res.ContentType = 'application/json; charset=utf-8'
          $res.StatusCode = 200
          $res.OutputStream.Write($bytes, 0, $bytes.Length)
        }
        default {
          $res.StatusCode = 404
          $bytes = [System.Text.Encoding]::UTF8.GetBytes('Not Found')
          $res.OutputStream.Write($bytes, 0, $bytes.Length)
        }
      }
    } finally {
      $res.OutputStream.Close()
    }
  }
}
finally {
  $listener.Stop()
}
