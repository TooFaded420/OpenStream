# Stream Deck Plugin Installer
# Installs essential plugins for OpenClaw integration

$script:Version = "1.0.0"
$script:PluginManifestUrl = "https://raw.githubusercontent.com/elgatosf/streamdeck-plugins/main/plugins.json"
$script:DownloadDir = "$env:TEMP\streamdeck-plugins"

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp [$Level] $Message" | Write-Host
}

function Install-StreamDeckPlugin {
    param(
        [string]$PluginName,
        [string]$DownloadUrl,
        [string]$Version = "latest"
    )
    
    $pluginDir = "$env:APPDATA\Elgato\StreamDeck\Plugins"
    $targetFolder = "$PluginName.sdPlugin"
    $targetPath = Join-Path $pluginDir $targetFolder
    
    if (Test-Path $targetPath) {
        Write-Log "Plugin $PluginName already installed" "WARN"
        return $false
    }
    
    Write-Log "Installing $PluginName..."
    
    try {
        if (-not (Test-Path $script:DownloadDir)) {
            New-Item -ItemType Directory -Path $script:DownloadDir -Force | Out-Null
        }
        
        $downloadPath = Join-Path $script:DownloadDir "$PluginName.zip"
        
        # Download plugin
        Write-Log "Downloading from $DownloadUrl..."
        Invoke-WebRequest -Uri $DownloadUrl -OutFile $downloadPath -UseBasicParsing
        
        # Extract to temp
        $extractPath = Join-Path $script:DownloadDir $PluginName
        Expand-Archive -Path $downloadPath -DestinationPath $extractPath -Force
        
        # Move to Stream Deck plugins folder
        Move-Item -Path $extractPath -Destination $targetPath -Force
        
        Write-Log "Successfully installed $PluginName" "SUCCESS"
        return $true
        
    } catch {
        Write-Log "Failed to install $PluginName`: $_" "ERROR"
        return $false
    }
}

function Install-BarRaiderWinTools {
    Write-Log "Installing BarRaider Windows Utils..."
    
    # BarRaider plugins are distributed via GitHub releases
    $releaseUrl = "https://api.github.com/repos/barraider/streamdeck-wintools/releases/latest"
    
    try {
        $release = Invoke-RestMethod -Uri $releaseUrl
        $asset = $release.assets | Where-Object { $_.name -like "*.streamDeckPlugin" } | Select-Object -First 1
        
        if ($asset) {
            return Install-StreamDeckPlugin -PluginName "com.barraider.wintools" -DownloadUrl $asset.browser_download_url
        } else {
            Write-Log "Could not find plugin asset in release" "ERROR"
            return $false
        }
    } catch {
        Write-Log "Failed to get BarRaider release: $_" "ERROR"
        return $false
    }
}

function Install-BarRaiderStreamDeckTools {
    Write-Log "Installing BarRaider Stream Deck Tools..."
    
    $releaseUrl = "https://api.github.com/repos/barraider/streamdeck-tools/releases/latest"
    
    try {
        $release = Invoke-RestMethod -Uri $releaseUrl
        $asset = $release.assets | Where-Object { $_.name -like "*.streamDeckPlugin" } | Select-Object -First 1
        
        if ($asset) {
            return Install-StreamDeckPlugin -PluginName "com.barraider.streamdecktools" -DownloadUrl $asset.browser_download_url
        } else {
            Write-Log "Could not find plugin asset" "ERROR"
            return $false
        }
    } catch {
        Write-Log "Failed to get release: $_" "ERROR"
        return $false
    }
}

function Install-AudioMeter {
    Write-Log "Installing Audio Meter..."
    
    $releaseUrl = "https://api.github.com/repos/fredemmott/streamdeck-audiometer/releases/latest"
    
    try {
        $release = Invoke-RestMethod -Uri $releaseUrl
        $asset = $release.assets | Where-Object { $_.name -like "*.streamDeckPlugin" } | Select-Object -First 1
        
        if ($asset) {
            return Install-StreamDeckPlugin -PluginName "com.fredemmott.audiometer" -DownloadUrl $asset.browser_download_url
        } else {
            Write-Log "Could not find plugin asset" "ERROR"
            return $false
        }
    } catch {
        Write-Log "Failed to get release: $_" "ERROR"
        return $false
    }
}

function Install-OpenClawWebhooks {
    param([string]$GatewayUrl = "http://127.0.0.1:18790")
    
    Write-Log "Setting up OpenClaw webhook integration..."
    
    # Create a custom action manifest for OpenClaw webhooks
    $openclawPluginDir = "$env:APPDATA\Elgato\StreamDeck\Plugins\com.openclaw.webhooks.sdPlugin"
    
    if (-not (Test-Path $openclawPluginDir)) {
        New-Item -ItemType Directory -Path $openclawPluginDir -Force | Out-Null
    }
    
    # Create manifest
    $manifest = @{
        Actions = @(
            @{
                Name = "OpenClaw TTS"
                UUID = "com.openclaw.webhooks.tts"
                Icon = "tts-icon"
                Tooltip = "Send TTS message"
                States = @(@{ Image = "tts-icon"; Title = "TTS" })
            }
            @{
                Name = "OpenClaw Spawn Agent"
                UUID = "com.openclaw.webhooks.spawn"
                Icon = "spawn-icon"
                Tooltip = "Spawn sub-agent"
                States = @(@{ Image = "spawn-icon"; Title = "Spawn" })
            }
            @{
                Name = "OpenClaw Status"
                UUID = "com.openclaw.webhooks.status"
                Icon = "status-icon"
                Tooltip = "Check OpenClaw status"
                States = @(@{ Image = "status-icon"; Title = "Status" })
            }
        )
        Category = "OpenClaw"
        CategoryIcon = "category-icon"
        CodePathWin = "openclaw-webhooks.exe"
        Description = "Control OpenClaw from your Stream Deck"
        Name = "OpenClaw Webhooks"
        UUID = "com.openclaw.webhooks"
        Version = "1.0.0"
        Author = "OpenClaw Community"
        URL = "https://openclaw.ai"
    }
    
    $manifest | ConvertTo-Json -Depth 5 | Out-File "$openclawPluginDir\manifest.json" -Encoding UTF8
    
    # Create webhook handlers script
    $webhookScript = @"
# OpenClaw Webhook Handlers
`$GatewayUrl = "$GatewayUrl"

function Invoke-OpenClawTTS {
    param([string]`$Text)
    
    `$body = @{
        text = `$Text
    } | ConvertTo-Json
    
    Invoke-RestMethod -Uri "`$GatewayUrl/tts" -Method Post -Body `$body -ContentType "application/json"
}

function Invoke-OpenClawSpawn {
    param([string]`$Task)
    
    `$body = @{
        task = `$Task
    } | ConvertTo-Json
    
    Invoke-RestMethod -Uri "`$GatewayUrl/spawn" -Method Post -Body `$body -ContentType "application/json"
}

function Get-OpenClawStatus {
    Invoke-RestMethod -Uri "`$GatewayUrl/status" -Method Get
}
"@
    
    $webhookScript | Out-File "$openclawPluginDir\webhooks.ps1" -Encoding UTF8
    
    Write-Log "OpenClaw webhook plugin created at $openclawPluginDir" "SUCCESS"
    
    return $true
}

# Main execution
Write-Log "=== Stream Deck Plugin Installer v$script:Version ==="

$installed = @()
$failed = @()

# Install essential plugins
$plugins = @(
    @{ Name = "BarRaider Windows Utils"; Function = ${function:Install-BarRaiderWinTools} }
    @{ Name = "BarRaider Stream Deck Tools"; Function = ${function:Install-BarRaiderStreamDeckTools} }
    @{ Name = "Audio Meter"; Function = ${function:Install-AudioMeter} }
)

foreach ($plugin in $plugins) {
    Write-Log ""
    Write-Log "Installing $($plugin.Name)..."
    $result = & $plugin.Function
    
    if ($result) {
        $installed += $plugin.Name
    } else {
        $failed += $plugin.Name
    }
}

# Setup OpenClaw integration
Write-Log ""
$openclawResult = Install-OpenClawWebhooks

if ($openclawResult) {
    $installed += "OpenClaw Webhooks"
}

# Summary
Write-Log ""
Write-Log "=== Installation Summary ==="
Write-Log "Installed: $($installed.Count)"
foreach ($name in $installed) {
    Write-Log "  ✓ $name" "SUCCESS"
}

if ($failed.Count -gt 0) {
    Write-Log ""
    Write-Log "Failed: $($failed.Count)" "ERROR"
    foreach ($name in $failed) {
        Write-Log "  ✗ $name" "ERROR"
    }
}

Write-Log ""
Write-Log "Please restart the Stream Deck software to see the new plugins"

# Return results
@{
    Installed = $installed
    Failed = $failed
    OpenClawPluginDir = "$env:APPDATA\Elgato\StreamDeck\Plugins\com.openclaw.webhooks.sdPlugin"
}
