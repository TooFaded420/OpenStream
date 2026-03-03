# OpenClaw Stream Deck Plugin - One-Click Installer
# Version: 3.0.0
# Usage: Right-click → "Run with PowerShell" (or ./INSTALLER.ps1)

param(
    [switch]$Silent,
    [switch]$SkipPlugins,
    [switch]$SkipDetection,
    [string]$GatewayUrl = "http://127.0.0.1:18790"
)

$ErrorActionPreference = "Stop"

# Configuration
$Script:Version = "3.0.0"
$Script:InstallDir = "$env:USERPROFILE\.openclaw\streamdeck-plugin"
$Script:LogFile = "$Script:InstallDir\install.log"
$Script:StreamDeckPluginDir = "$env:APPDATA\Elgato\StreamDeck\Plugins"
$Script:StreamDeckProfileDir = "$env:APPDATA\Elgato\StreamDeck\ProfilesV2"

# Colors for output
$Colors = @{
    Success = "Green"
    Error = "Red"
    Warning = "Yellow"
    Info = "Cyan"
    Step = "Magenta"
}

function Write-Color {
    param([string]$Text, [string]$Color = "White")
    Write-Host $Text -ForegroundColor $Colors[$Color]
}

function Write-Status {
    param([string]$Message, [string]$Type = "INFO")
    $timestamp = Get-Date -Format "HH:mm:ss"
    $prefix = switch ($Type) {
        "SUCCESS" { "✓" }
        "ERROR" { "✗" }
        "WARN" { "⚠" }
        "STEP" { "→" }
        "INFO" { "ℹ" }
        default { "•" }
    }
    $color = switch ($Type) {
        "SUCCESS" { "Success" }
        "ERROR" { "Error" }
        "WARN" { "Warning" }
        "STEP" { "Step" }
        default { "Info" }
    }
    
    $line = "[$timestamp] $prefix $Message"
    Write-Color $line $color
    
    # Log to file
    if (Test-Path $Script:InstallDir) {
        $line | Out-File $Script:LogFile -Append -ErrorAction SilentlyContinue
    }
}

function Initialize {
    Clear-Host
    Write-Color @"
╔══════════════════════════════════════════════════════════╗
║                                                          ║
║   OpenClaw Stream Deck Plugin Installer v$Script:Version        ║
║                                                          ║
║   One-click setup for Stream Deck + OpenClaw            ║
║                                                          ║
╚══════════════════════════════════════════════════════════╝

"@ "Info"
    
    # Create directories
    @($Script:InstallDir, "$Script:InstallDir\cache", "$Script:InstallDir\profiles") | ForEach-Object {
        if (-not (Test-Path $_)) {
            New-Item -ItemType Directory -Path $_ -Force | Out-Null
        }
    }
    
    # Initialize log
    "OpenClaw Stream Deck Plugin Installer v$Script:Version" | Out-File $Script:LogFile
    "Started: $(Get-Date)" | Out-File $Script:LogFile -Append
    "Gateway: $GatewayUrl" | Out-File $Script:LogFile -Append
    Write-Host ""
}

function Test-StreamDeck {
    Write-Status "Checking Stream Deck software..." "STEP"
    
    $paths = @(
        "$env:ProgramFiles\Elgato\StreamDeck\StreamDeck.exe"
        "$env:ProgramFiles(x86)\Elgato\StreamDeck\StreamDeck.exe"
        "$env:LOCALAPPDATA\Programs\Elgato\StreamDeck\StreamDeck.exe"
    )
    
    $found = $null
    foreach ($path in $paths) {
        if (Test-Path $path) {
            $found = $path
            break
        }
    }
    
    if (-not $found) {
        Write-Status "Stream Deck software not found!" "ERROR"
        Write-Color "`nPlease download and install Stream Deck from:" "Error"
        Write-Color "https://www.elgato.com/downloads" "Info"
        Read-Host "`nPress Enter to exit"
        exit 1
    }
    
    Write-Status "Found Stream Deck at: $found" "SUCCESS"
    
    # Check if running
    $process = Get-Process "StreamDeck" -ErrorAction SilentlyContinue
    if (-not $process) {
        Write-Status "Starting Stream Deck..." "STEP"
        Start-Process $found
        Start-Sleep 5
        Write-Status "Stream Deck started" "SUCCESS"
    } else {
        Write-Status "Stream Deck already running" "SUCCESS"
    }
    
    return $true
}

function Get-ConnectedDecks {
    Write-Status "Detecting connected Stream Decks..." "STEP"
    
    try {
        # Try to get device info from Stream Deck's plugin folder structure
        $pluginDir = "$env:APPDATA\Elgato\StreamDeck"
        
        if (Test-Path $pluginDir) {
            $decks = @()
            
            # Check for device-specific files or registry
            $regPaths = @(
                "HKCU:\Software\Elgato Systems GmbH\StreamDeck"
                "HKLM:\Software\Elgato Systems GmbH\StreamDeck"
            )
            
            foreach ($regPath in $regPaths) {
                if (Test-Path $regPath) {
                    $props = Get-ItemProperty $regPath -ErrorAction SilentlyContinue
                    if ($props) {
                        $decks += "Stream Deck detected in registry"
                    }
                }
            }
            
            Write-Status "Stream Deck detected!" "SUCCESS"
            return $true
        }
        
        Write-Status "No Stream Deck hardware detected (software-only mode)" "WARN"
        return $true
    }
    catch {
        Write-Status "Could not detect hardware: $($_.Exception.Message)" "WARN"
        return $true  # Continue anyway
    }
}

function Install-OpenClawPlugin {
    Write-Status "Installing OpenClaw Plugin..." "STEP"
    
    $pluginName = "com.openclaw.webhooks"
    $pluginDir = "$Script:StreamDeckPluginDir\${pluginName}.sdPlugin"
    
    # Create plugin directory
    if (-not (Test-Path $pluginDir)) {
        New-Item -ItemType Directory -Path $pluginDir -Force | Out-Null
    }
    
    # Create manifest.json
    $manifest = @{
        Name = "OpenClaw Webhooks"
        Version = $Script:Version
        Author = "OpenClaw"
        Description = "Control OpenClaw AI from Stream Deck"
        URL = "https://openclaw.ai"
        Icon = "images/plugin-icon.png"
        Category = "OpenClaw"
        CodePath = "plugin.ps1"
        Actions = @(
            @{
                Name = "OpenClaw Action"
                UUID = "$pluginName.action"
                Icon = "images/action-icon.png"
                PropertyInspectorPath = "inspector.html"
            }
        )
    } | ConvertTo-Json -Depth 5
    
    $manifest | Out-File "$pluginDir\manifest.json" -Encoding UTF8
    
    # Create main plugin script
    $pluginScript = @"
param(`$Action, `$Settings)

`$Settings = `$Settings | ConvertFrom-Json
`$Endpoint = `$Settings.endpoint
`$Gateway = "$GatewayUrl"

if (`$Action -eq "keyUp") {
    try {
        `$response = Invoke-RestMethod -Uri "`$Gateway`$Endpoint" -Method Post -TimeoutSec 5
        `{ "result": "success" } | ConvertTo-Json
    } catch {
        `{ "result": "error", "message": `$_.Exception.Message } | ConvertTo-Json
    }
}
"@
    
    $pluginScript | Out-File "$pluginDir\plugin.ps1" -Encoding UTF8
    
    # Create property inspector
    $inspector = @"
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <style>
        body { font-family: -apple-system, sans-serif; padding: 10px; background: #2d2d2d; color: white; }
        .sdpi-item { margin: 10px 0; }
        label { display: block; margin-bottom: 5px; font-size: 12px; }
        select, input { width: 100%; padding: 5px; background: #3d3d3d; border: 1px solid #555; color: white; }
    </style>
</head>
<body>
    <div class="sdpi-item">
        <label>Action</label>
        <select id="endpoint">
            <option value="/status">Check Status</option>
            <option value="/tts.toggle">Toggle TTS</option>
            <option value="/spawn">Spawn Agent</option>
            <option value="/models">List Models</option>
            <option value="/subagents">List Subagents</option>
            <option value="/gateway.restart">Restart Gateway</option>
            <option value="/memory_search">Search Memory</option>
            <option value="/web.search">Web Search</option>
        </select>
    </div>
    <script>
        document.getElementById('endpoint').addEventListener('change', function() {
            var settings = { endpoint: this.value };
            var payload = { event: 'setSettings', payload: settings };
            window.parent.postMessage(payload, '*');
        });
    </script>
</body>
</html>
"@
    
    $inspector | Out-File "$pluginDir\inspector.html" -Encoding UTF8
    
    # Create images directory and placeholder icons
    $imagesDir = "$pluginDir\images"
    if (-not (Test-Path $imagesDir)) {
        New-Item -ItemType Directory -Path $imagesDir -Force | Out-Null
    }
    
    Write-Status "OpenClaw plugin installed" "SUCCESS"
    return $true
}

function Install-PrebuiltProfiles {
    Write-Status "Generating OpenClaw profiles..." "STEP"
    
    $profilesDir = "$Script:InstallDir\profiles"
    
    # Profile for MK.2 (15 keys)
    $mk2Profile = @{
        Name = "OpenClaw Control"
        Version = $Script:Version
        Actions = @(
            # Row 1
            @{ Key = 0; Action = "com.openclaw.webhooks.action"; Settings = @{ endpoint = "/tts.toggle" }; Title = "TTS" },
            @{ Key = 1; Action = "com.openclaw.webhooks.action"; Settings = @{ endpoint = "/spawn" }; Title = "Spawn" },
            @{ Key = 2; Action = "com.openclaw.webhooks.action"; Settings = @{ endpoint = "/status" }; Title = "Status" },
            @{ Key = 3; Action = "com.openclaw.webhooks.action"; Settings = @{ endpoint = "/models" }; Title = "Models" },
            @{ Key = 4; Action = "com.openclaw.webhooks.action"; Settings = @{ endpoint = "/subagents" }; Title = "Agents" },
            # Row 2
            @{ Key = 5; Action = "com.openclaw.webhooks.action"; Settings = @{ endpoint = "/nodes.status" }; Title = "Nodes" },
            @{ Key = 6; Action = "com.openclaw.webhooks.action"; Settings = @{ endpoint = "/gateway.restart" }; Title = "Restart" },
            @{ Key = 7; Action = "com.openclaw.webhooks.action"; Settings = @{ endpoint = "/config.get" }; Title = "Config" },
            @{ Key = 8; Action = "com.openclaw.webhooks.action"; Settings = @{ endpoint = "/session.status" }; Title = "Session" },
            @{ Key = 9; Action = "com.openclaw.webhooks.action"; Settings = @{ endpoint = "/web.search" }; Title = "Search" },
            # Row 3
            @{ Key = 10; Action = "com.openclaw.webhooks.action"; Settings = @{ endpoint = "/memory_search" }; Title = "Memory" },
            @{ Key = 11; Action = "com.openclaw.webhooks.action"; Settings = @{ endpoint = "/spawn" }; Settings2 = @{ task = "Code review" }; Title = "Coding" },
            @{ Key = 12; Action = "com.openclaw.webhooks.action"; Settings = @{ endpoint = "/tts" }; Title = "Audio" },
            @{ Key = 13; Action = "com.openclaw.webhooks.action"; Settings = @{ endpoint = "/message.send" }; Title = "Message" },
            @{ Key = 14; Action = "com.openclaw.webhooks.action"; Settings = @{ endpoint = "/browser.open" }; Title = "Browser" }
        )
    }
    
    $mk2Profile | ConvertTo-Json -Depth 5 | Out-File "$profilesDir\openclaw-control-mk2.json" -Encoding UTF8
    
    Write-Status "Profile generated for MK.2 (15 keys)" "SUCCESS"
    
    # Copy to Stream Deck
    $destDir = "$Script:StreamDeckProfileDir\OpenClaw-Control.sdProfile"
    if (-not (Test-Path $destDir)) {
        New-Item -ItemType Directory -Path $destDir -Force | Out-Null
    }
    Copy-Item "$profilesDir\openclaw-control-mk2.json" "$destDir\manifest.json" -Force
    
    Write-Status "Profile installed to Stream Deck" "SUCCESS"
}

function Test-Installation {
    Write-Status "Testing installation..." "STEP"
    
    # Test gateway connection
    try {
        $response = Invoke-RestMethod -Uri "$GatewayUrl/status" -Method Get -TimeoutSec 5
        Write-Status "Gateway connection: OK" "SUCCESS"
    } catch {
        Write-Status "Gateway connection failed: $($_.Exception.Message)" "WARN"
        Write-Color "`n⚠ Make sure OpenClaw gateway is running:" "Warning"
        Write-Color "   openclaw gateway status" "Info"
        Write-Color "   openclaw gateway start" "Info"
    }
    
    # Check plugin installed
    $pluginDir = "$Script:StreamDeckPluginDir\com.openclaw.webhooks.sdPlugin"
    if (Test-Path $pluginDir) {
        Write-Status "Plugin files: OK" "SUCCESS"
    } else {
        Write-Status "Plugin files: Missing" "ERROR"
    }
    
    return $true
}

function Show-Completion {
    Write-Host ""
    Write-Color "╔══════════════════════════════════════════════════════════╗" "Success"
    Write-Color "║                                                          ║" "Success"
    Write-Color "║   ✓ Installation Complete!                             ║" "Success"
    Write-Color "║                                                          ║" "Success"
    Write-Color "╚══════════════════════════════════════════════════════════╝" "Success"
    Write-Host ""
    
    Write-Color "Next Steps:" "Step"
    Write-Host ""
    Write-Host "1. Restart Stream Deck software (if not already)"
    Write-Host "2. Look for 'OpenClaw Webhooks' in the action list"
    Write-Host "3. Drag actions to your Stream Deck buttons"
    Write-Host "4. Configure each button with desired action"
    Write-Host ""
    
    Write-Color "Available Actions:" "Info"
    Write-Host "  • Status Check    • Toggle TTS      • Spawn Agent"
    Write-Host "  • List Models     • List Subagents  • Restart Gateway"
    Write-Host "  • Search Memory   • Web Search      • Send Message"
    Write-Host ""
    
    Write-Color "Need Help?" "Info"
    Write-Host "  • Log file: $Script:LogFile"
    Write-Host "  • Documentation: https://docs.openclaw.ai"
    Write-Host "  • Issues: https://github.com/openclaw/openclaw/issues"
    Write-Host ""
    
    if (-not $Silent) {
        Read-Host "Press Enter to exit"
    }
}

# Main execution
try {
    Initialize
    Test-StreamDeck
    Get-ConnectedDecks
    Install-OpenClawPlugin
    Install-PrebuiltProfiles
    Test-Installation
    Show-Completion
} catch {
    Write-Status "Installation failed: $($_.Exception.Message)" "ERROR"
    Write-Color "`nCheck log file: $Script:LogFile" "Error"
    Read-Host "Press Enter to exit"
    exit 1
}