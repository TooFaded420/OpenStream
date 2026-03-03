# Advanced Auto-Detection for Stream Deck Skill
# Detects hardware, software, network, and OpenClaw setup

$ErrorActionPreference = "SilentlyContinue"

$DetectionReport = @{
    Timestamp = Get-Date -Format "o"
    Hardware = @{}
    Software = @{}
    Network = @{}
    OpenClaw = @{}
    Recommendations = @()
}

Write-Host "Running advanced detection..." -ForegroundColor Cyan

# 1. Hardware Detection
Write-Host "Detecting hardware..." -NoNewline
$usbDevices = Get-PnpDevice -Class USB | Where-Object { 
    $_.InstanceId -like "*0FD9*" -or $_.FriendlyName -like "*Stream Deck*"
}

$DetectionReport.Hardware.Devices = $usbDevices | ForEach-Object { @{
    Name = $_.FriendlyName
    Status = $_.Status
    InstanceId = $_.InstanceId
}}

$DetectionReport.Hardware.Count = $usbDevices.Count
Write-Host " Found $($usbDevices.Count) device(s)" -ForegroundColor Green

# 2. Software Detection
Write-Host "Checking software..." -NoNewline
$sdInstalled = Test-Path "$env:ProgramFiles\Elgato\StreamDeck\StreamDeck.exe"
$sdRunning = Get-Process "StreamDeck" -ErrorAction SilentlyContinue

$DetectionReport.Software.Installed = $sdInstalled
$DetectionReport.Software.Running = $sdRunning -ne $null
$DetectionReport.Software.Version = if ($sdInstalled) { "Installed" } else { "Not Installed" }

if (-not $sdInstalled) {
    $DetectionReport.Recommendations += "Install Stream Deck software from elgato.com"
}
Write-Host " Done" -ForegroundColor Green

# 3. Network Detection (Tailscale)
Write-Host "Checking network..." -NoNewline
$tailscaleStatus = & tailscale status 2>$null
if ($tailscaleStatus) {
    $DetectionReport.Network.Tailscale = $true
    $DetectionReport.Network.Nodes = ($tailscaleStatus | Select-String "\d+\.\d+\.\d+\.\d+").Matches.Value
} else {
    $DetectionReport.Network.Tailscale = $false
}
Write-Host " Done" -ForegroundColor Green

# 4. OpenClaw Detection
Write-Host "Checking OpenClaw..." -NoNewline
$openclawInstalled = Get-Command "openclaw" -ErrorAction SilentlyContinue
$gatewayStatus = & openclaw gateway status 2>$null

$DetectionReport.OpenClaw.Installed = $openclawInstalled -ne $null
$DetectionReport.OpenClaw.GatewayRunning = $gatewayStatus -match "running"

if ($DetectionReport.OpenClaw.GatewayRunning) {
    if ($gatewayStatus -match "port\s+(\d+)") {
        $DetectionReport.OpenClaw.Port = $Matches[1]
    }
}

if (-not $DetectionReport.OpenClaw.Installed) {
    $DetectionReport.Recommendations += "Install OpenClaw: npm install -g openclaw"
}
if (-not $DetectionReport.OpenClaw.GatewayRunning) {
    $DetectionReport.Recommendations += "Start OpenClaw gateway: openclaw gateway start"
}
Write-Host " Done" -ForegroundColor Green

# 5. Check for Multiple Gateways
$DetectionReport.OpenClaw.HasMultipleGateways = $DetectionReport.Network.Tailscale -and ($DetectionReport.Network.Nodes.Count -gt 1)

# Save report
$reportPath = "$env:USERPROFILE\.openclaw\streamdeck-detection-report.json"
$DetectionReport | ConvertTo-Json -Depth 10 | Out-File $reportPath -Encoding UTF8

Write-Host ""
Write-Host "Detection Report:" -ForegroundColor Cyan
Write-Host "  Hardware: $($DetectionReport.Hardware.Count) Stream Deck(s)"
Write-Host "  Software: $(if($DetectionReport.Software.Installed){'Installed'}else{'Not installed'})"
Write-Host "  OpenClaw: $(if($DetectionReport.OpenClaw.GatewayRunning){'Running'}else{'Not running'})"
Write-Host "  Tailscale: $(if($DetectionReport.Network.Tailscale){'Active'}else{'Not detected'})"

if ($DetectionReport.Recommendations.Count -gt 0) {
    Write-Host ""
    Write-Host "Recommendations:" -ForegroundColor Yellow
    foreach ($rec in $DetectionReport.Recommendations) {
        Write-Host "  • $rec" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "Full report saved to: $reportPath" -ForegroundColor Gray