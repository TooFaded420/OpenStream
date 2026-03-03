# Stream Deck Auto-Setup Orchestrator
# Modular - runs modules in sequence or individually
# Usage: .\ORCHESTRATOR.ps1 [-Modules @("Detect", "Install", "Config", "Service")]

param(
    [string[]]$Modules = @("Detect", "Install", "Config"),
    [switch]$AutoStart
)

$ErrorActionPreference = "Stop"
$ModulePath = "$PSScriptRoot\MODULES"

Write-Host "OpenClaw Stream Deck Orchestrator" -ForegroundColor Cyan
Write-Host "Running modules: $($Modules -join ', ')" -ForegroundColor Gray
Write-Host ""

$Results = @{
    Detection = $null
    Installation = $null
    Config = $null
    Service = $null
}

# Run Detection
if ("Detect" -in $Modules) {
    Write-Host "[1/4] Running Detection Module..." -NoNewline
    $Results.Detection = & "$ModulePath\Module-Detector.ps1"
    Write-Host " OK" -ForegroundColor Green
    Write-Host "    Found: $($Results.Detection.Hardware.Count) device(s)" -ForegroundColor Gray
}

# Run Installer
if ("Install" -in $Modules -and $Results.Detection) {
    Write-Host "[2/4] Running Installer Module..." -NoNewline
    $Results.Installation = & "$ModulePath\Module-Installer.ps1" -Detection $Results.Detection
    Write-Host " OK" -ForegroundColor Green
    Write-Host "    Plugin: $(if($Results.Installation.PluginInstalled){'Installed'}else{'Already present'})" -ForegroundColor Gray
}

# Run Config
if ("Config" -in $Modules) {
    Write-Host "[3/4] Running Config Module..." -NoNewline
    $Results.Config = & "$ModulePath\Module-Config.ps1"
    Write-Host " OK" -ForegroundColor Green
    Write-Host "    Gateways: $($Results.Config.PrimaryGateway) + $($Results.Config.SecondaryGateway)" -ForegroundColor Gray
}

# Run Service
if ("Service" -in $Modules) {
    Write-Host "[4/4] Running Service Module..." -NoNewline
    $Results.Service = & "$ModulePath\Module-Service.ps1" -Action "Start"
    Write-Host " OK" -ForegroundColor Green
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "Orchestration Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green

if ($AutoStart) {
    # Auto-start Stream Deck
    $sdPath = "$env:ProgramFiles\Elgato\StreamDeck\StreamDeck.exe"
    if (Test-Path $sdPath) { Start-Process $sdPath }
}

return $Results