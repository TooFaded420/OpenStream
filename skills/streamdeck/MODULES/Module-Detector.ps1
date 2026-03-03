# Detection Module
# Usage: .\Module-Detector.ps1
# Returns: Detection results as object

$Detection = @{
    Hardware = @()
    Software = @{}
    OpenClaw = @{}
    Timestamp = Get-Date -Format "o"
}

# Detect hardware
$usbDevices = Get-PnpDevice -Class USB | Where-Object { $_.InstanceId -like "*0FD9*" }
$Detection.Hardware = $usbDevices | ForEach-Object { $_.FriendlyName }

# Detect software
$sdPaths = @(
    "$env:ProgramFiles\Elgato\StreamDeck\StreamDeck.exe",
    "$env:LOCALAPPDATA\Programs\Elgato\StreamDeck\StreamDeck.exe"
)
$Detection.Software.Installed = $sdPaths | Where-Object { Test-Path $_ } | Select-Object -First 1
$Detection.Software.Running = (Get-Process "StreamDeck" -ErrorAction SilentlyContinue) -ne $null

# Detect OpenClaw
$Detection.OpenClaw.Installed = (Get-Command "openclaw" -ErrorAction SilentlyContinue) -ne $null
try {
    Invoke-RestMethod -Uri "http://127.0.0.1:18790/status" -Method Get -TimeoutSec 2 | Out-Null
    $Detection.OpenClaw.GatewayRunning = $true
} catch {
    $Detection.OpenClaw.GatewayRunning = $false
}

# Output
return $Detection