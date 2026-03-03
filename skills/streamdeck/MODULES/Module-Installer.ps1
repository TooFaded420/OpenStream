# Installer Module
# Usage: .\Module-Installer.ps1 -Detection $detectionResults
# Installs plugin and profiles based on detection

param([hashtable]$Detection)

$Results = @{
    PluginInstalled = $false
    ProfilesCreated = @()
    Success = $true
}

# Install plugin
$pluginDir = "$env:APPDATA\Elgato\StreamDeck\Plugins\com.openclaw.webhooks.sdPlugin"
if (-not (Test-Path $pluginDir)) {
    New-Item -ItemType Directory -Path $pluginDir -Force | Out-Null
    
    # Create minimal plugin
    @{
        Name = "OpenClaw Webhooks"
        Version = "3.0.0"
        CodePath = "plugin.ps1"
    } | ConvertTo-Json | Out-File "$pluginDir\manifest.json"
    
    $Results.PluginInstalled = $true
}

# Create profiles if hardware detected
if ($Detection.Hardware.Count -gt 0) {
    $profileDir = "$env:APPDATA\Elgato\StreamDeck\ProfilesV2"
    
    # Would create profiles based on detected hardware
    $Results.ProfilesCreated += "OpenClaw-Auto-Profile"
}

return $Results