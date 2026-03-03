# Configuration Module
# Usage: .\Module-Config.ps1
# Sets up gateway config and button layouts

$Config = @{
    PrimaryGateway = "http://127.0.0.1:18790"
    SecondaryGateway = $null
    AutoSwitch = $true
    Profiles = @("MK2", "Plus")
}

# Detect secondary gateway (Tailscale)
$tailscaleIP = "100.92.222.41"
try {
    Test-Connection -ComputerName $tailscaleIP -Count 1 -Quiet
    $Config.SecondaryGateway = "http://${tailscaleIP}:18789"
} catch {}

# Save config
$configDir = "$env:USERPROFILE\.openclaw\streamdeck-plugin"
if (-not (Test-Path $configDir)) { New-Item -ItemType Directory -Path $configDir -Force | Out-Null }
$Config | ConvertTo-Json | Out-File "$configDir\auto-config.json" -Encoding UTF8

return $Config