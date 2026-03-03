# Stream Deck Auto-Setup v3 - Working Downloads
# Uses direct Elgato Marketplace URLs

param([switch]$Silent)

$script:Version = "3.0.0"
$script:SetupDir = "$env:USERPROFILE\.openclaw\streamdeck-setup"
$script:CacheDir = "$script:SetupDir\cache"
$script:LogFile = "$script:SetupDir\setup.log"

# Direct download URLs (Elgato Marketplace)
$script:PluginURLs = @{
    "com.barraider.wintools" = @{
        Name = "Windows Utils"
        URL = "https://app-updates.elgato.com/plugins/com.barraider.wintools/1.2.5/com.barraider.wintools.streamDeckPlugin"
        Version = "1.2.5"
    }
    "com.barraider.streamdecktools" = @{
        Name = "Stream Deck Tools"
        URL = "https://app-updates.elgato.com/plugins/com.barraider.streamdecktools/0.3.0/com.barraider.streamdecktools.streamDeckPlugin"
        Version = "0.3.0"
    }
    "com.barraider.advancedlauncher" = @{
        Name = "Advanced Launcher"
        URL = "https://app-updates.elgato.com/plugins/com.barraider.advancedlauncher/1.5.0/com.barraider.advancedlauncher.streamDeckPlugin"
        Version = "1.5.0"
    }
    "com.fredemmott.audiometer" = @{
        Name = "Audio Meter"
        URL = "https://github.com/fredemmott/streamdeck-audiometer/releases/download/v1.0.0/com.fredemmott.audiometer.streamDeckPlugin"
        Version = "1.0.0"
    }
}

function Write-Status {
    param([string]$Message, [string]$Type = "INFO")
    $timestamp = Get-Date -Format "HH:mm:ss"
    $prefix = switch ($Type) { "SUCCESS" { "[OK]" } "ERROR" { "[ERR]" } "WARN" { "[!]" } "STEP" { "[>]" } default { "[i]" } }
    $line = "$timestamp $prefix $Message"
    Write-Host $line
    if (-not $Silent) { $line | Out-File $LogFile -Append -ErrorAction SilentlyContinue }
}

function Initialize {
    Write-Status "Stream Deck Auto-Setup v$script:Version" "STEP"
    
    @($script:SetupDir, $script:CacheDir) | ForEach-Object {
        if (-not (Test-Path $_)) { New-Item -ItemType Directory -Path $_ -Force | Out-Null }
    }
    
    if (Test-Path $LogFile) { Remove-Item $LogFile -Force -ErrorAction SilentlyContinue }
    
    Write-Host ""
    Write-Host "=========================================="
    Write-Host "  Stream Deck + OpenClaw Auto-Setup     "
    Write-Host "  Working Downloads - Elgato & GitHub    "
    Write-Host "=========================================="
    Write-Host ""
}

function Test-StreamDeck {
    Write-Status "Checking Stream Deck..." "STEP"
    
    $paths = @(
        "$env:ProgramFiles\Elgato\StreamDeck\StreamDeck.exe"
        "$env:LOCALAPPDATA\Programs\Elgato\StreamDeck\StreamDeck.exe"
    )
    
    $found = $paths | Where-Object { Test-Path $_ } | Select-Object -First 1
    
    if (-not $found) {
        Write-Status "Stream Deck not found" "ERROR"
        Read-Host "Press Enter"
        exit 1
    }
    
    Write-Status "Found: $found" "SUCCESS"
    
    if (-not (Get-Process "StreamDeck" -ErrorAction SilentlyContinue)) {
        Write-Status "Starting Stream Deck..."
        Start-Process $found
        Start-Sleep 5
    }
    return $true
}

function Install-Plugin {
    param([string]$UUID)
    
    $plugin = $script:PluginURLs[$UUID]
    if (-not $plugin) {
        Write-Status "Unknown plugin: $UUID" "ERROR"
        return
    }
    
    $name = $plugin.Name
    $url = $plugin.URL
    $version = $plugin.Version
    
    Write-Status "Installing $name v$version..." "STEP"
    
    # Check if already installed
    $pluginDir = "$env:APPDATA\Elgato\StreamDeck\Plugins\$UUID.sdPlugin"
    if (Test-Path $pluginDir) {
        Write-Status "$name already installed" "SUCCESS"
        return
    }
    
    # Check cache
    $filename = "$UUID-$version.streamDeckPlugin"
    $cached = "$script:CacheDir\$filename"
    
    if (Test-Path $cached) {
        Write-Status "Using cached file" "INFO"
        $downloadPath = $cached
    } else {
        # Download
        try {
            Write-Status "Downloading from: $url"
            Invoke-WebRequest -Uri $url -OutFile $cached -UseBasicParsing -ErrorAction Stop
            $downloadPath = $cached
            Write-Status "Downloaded successfully" "SUCCESS"
        } catch {
            Write-Status "Download failed: $_" "ERROR"
            Write-Status "Manual install: https://apps.elgato.com/plugins/$UUID" "WARN"
            return
        }
    }
    
    # Install
    try {
        Write-Status "Installing $name..."
        Start-Process $downloadPath -Wait -ErrorAction SilentlyContinue
        Write-Status "$name installed successfully!" "SUCCESS"
    } catch {
        Write-Status "Install failed: $_" "ERROR"
    }
}

function Install-AllPlugins {
    Write-Status "Installing plugins..." "STEP"
    Write-Host ""
    
    $script:PluginURLs.Keys | ForEach-Object {
        Install-Plugin -UUID $_
        Write-Host ""
    }
}

function Setup-OpenClaw {
    Write-Status "Creating OpenClaw plugin..." "STEP"
    
    $dir = "$env:APPDATA\Elgato\StreamDeck\Plugins\com.openclaw.webhooks.sdPlugin"
    if (Test-Path $dir) { 
        Write-Status "OpenClaw plugin exists" "SUCCESS"
        return 
    }
    
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
    
    $manifest = @{
        Actions = @(
            @{ UUID = "com.openclaw.tts"; Name = "TTS"; Icon = "tts"; States = @(@{ Image = "tts"; Title = "TTS" }) }
            @{ UUID = "com.openclaw.spawn"; Name = "Spawn"; Icon = "spawn"; States = @(@{ Image = "spawn"; Title = "Spawn" }) }
            @{ UUID = "com.openclaw.status"; Name = "Status"; Icon = "status"; States = @(@{ Image = "status"; Title = "Status" }) }
        )
        Category = "OpenClaw"
        Name = "OpenClaw"
        UUID = "com.openclaw.webhooks"
        Version = "1.0"
    }
    $manifest | ConvertTo-Json -Depth 5 | Out-File "$dir\manifest.json"
    
    Write-Status "OpenClaw plugin created" "SUCCESS"
}

function Generate-Profiles {
    Write-Status "Generating profiles..." "STEP"
    
    $dir = "$env:USERPROFILE\.openclaw\streamdeck-profiles"
    New-Item -ItemType Directory -Path $dir -Force -ErrorAction SilentlyContinue | Out-Null
    
    @(
        @{ Name = "OpenClaw MK.2"; Model = "20GAI9901" }
        @{ Name = "OpenClaw XL"; Model = "20GBD9901" }
        @{ Name = "OpenClaw Plus"; Model = "20GBA9901" }
    ) | ForEach-Object {
        $id = [Guid]::NewGuid().ToString().ToUpper()
        $path = "$dir\$id.sdProfile"
        
        New-Item -ItemType Directory -Path $path, "$path\Profiles", "$path\Images" -Force | Out-Null
        
        $page = [Guid]::NewGuid().ToString()
        @{ Device = @{ Model = $_.Model; UUID = "gen-$id" }; Name = $_.Name; Pages = @{ Current = $page; Default = $page; Pages = @($page) }; Version = "2.0" } | 
            ConvertTo-Json -Depth 5 | Out-File "$path\manifest.json"
        
        @{ Controller = ""; Actions = @() } | ConvertTo-Json | Out-File "$path\Profiles\$page.json"
        
        Write-Status "  Created: $($_.Name)" "SUCCESS"
    }
    
    Write-Status "Profiles ready in: $dir" "SUCCESS"
}

function Show-Done {
    Write-Host ""
    Write-Host "=========================================="
    Write-Host "  Setup Complete!                       "
    Write-Host "=========================================="
    Write-Host ""
    Write-Status "Next steps:" "STEP"
    Write-Host "  1. Restart Stream Deck if plugins installed"
    Write-Host "  2. Import profiles from:"
    Write-Host "     $env:USERPROFILE\.openclaw\streamdeck-profiles\"
    Write-Host ""
    Write-Status "Log: $LogFile" "INFO"
    Write-Host ""
    Read-Host "Press Enter"
}

# Run
try {
    Initialize
    Test-StreamDeck
    Install-AllPlugins
    Setup-OpenClaw
    Generate-Profiles
    Show-Done
} catch {
    Write-Status "Error: $_" "ERROR"
    Read-Host "Press Enter"
}
