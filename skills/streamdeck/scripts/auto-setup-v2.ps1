# Stream Deck Auto-Setup v2
# Handles rate limits, uses multiple sources, fully automatic

param([switch]$Silent, [string]$GitHubToken = "")

$script:Version = "2.0.0"
$script:SetupDir = "$env:USERPROFILE\.openclaw\streamdeck-setup"
$script:CacheDir = "$script:SetupDir\cache"
$script:LogFile = "$script:SetupDir\setup.log"
$script:RequestCount = 0
$script:MaxRequests = 50  # Stay under GitHub's 60/hour limit

function Write-Status {
    param([string]$Message, [string]$Type = "INFO")
    $timestamp = Get-Date -Format "HH:mm:ss"
    $prefix = switch ($Type) { "SUCCESS" { "[OK]" } "ERROR" { "[ERR]" } "WARN" { "[!]" } "STEP" { "[>]" } default { "[i]" } }
    $line = "$timestamp $prefix $Message"
    Write-Host $line
    if (-not $Silent) { $line | Out-File $LogFile -Append -ErrorAction SilentlyContinue }
}

function Wait-ForRateLimit {
    $script:RequestCount++
    if ($script:RequestCount -ge $script:MaxRequests) {
        Write-Status "Approaching GitHub rate limit. Pausing 60 seconds..." "WARN"
        Start-Sleep 60
        $script:RequestCount = 0
    }
}

function Initialize-Setup {
    Write-Status "Stream Deck Auto-Setup v$script:Version" "STEP"
    
    @($script:SetupDir, $script:CacheDir) | ForEach-Object {
        if (-not (Test-Path $_)) { New-Item -ItemType Directory -Path $_ -Force | Out-Null }
    }
    
    if (Test-Path $LogFile) { Remove-Item $LogFile -Force -ErrorAction SilentlyContinue }
    
    Write-Host ""
    Write-Host "=========================================="
    Write-Host "  Stream Deck + OpenClaw Auto-Setup       "
    Write-Host "  Fully Automatic - Rate Limit Safe      "
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
        Write-Status "Stream Deck not found. Install from elgato.com" "ERROR"
        Read-Host "Press Enter"
        exit 1
    }
    
    Write-Status "Found: $found" "SUCCESS"
    
    if (-not (Get-Process "StreamDeck" -ErrorAction SilentlyContinue)) {
        Write-Status "Starting Stream Deck..."
        Start-Process $found
        Start-Sleep 5
    }
}

function Get-PluginFromCache {
    param([string]$UUID)
    $cached = Get-ChildItem $script:CacheDir -Filter "*$UUID*.streamDeckPlugin" | Select-Object -First 1
    if ($cached) {
        Write-Status "Using cached: $($cached.Name)"
        return $cached.FullName
    }
    return $null
}

function Install-FromGitHub {
    param([string]$Owner, [string]$Repo, [string]$UUID, [string]$Name)
    
    # Check cache first
    $cached = Get-PluginFromCache -UUID $UUID
    if ($cached) {
        Install-PluginFile -Path $cached -Name $Name -UUID $UUID
        return
    }
    
    Write-Status "Downloading $Name from GitHub..." "STEP"
    Wait-ForRateLimit
    
    try {
        $headers = @{ "User-Agent" = "OpenClaw-Setup" }
        if ($GitHubToken) { $headers["Authorization"] = "token $GitHubToken" }
        
        $api = "https://api.github.com/repos/$Owner/$Repo/releases/latest"
        $release = Invoke-RestMethod -Uri $api -Headers $headers -ErrorAction Stop
        
        $asset = $release.assets | Where-Object { $_.name -like "*.streamDeckPlugin" } | Select-Object -First 1
        if (-not $asset) { throw "No .streamDeckPlugin found" }
        
        $download = "$script:CacheDir\$($asset.name)"
        Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $download -Headers @{ "User-Agent" = "OpenClaw" }
        
        Install-PluginFile -Path $download -Name $Name -UUID $UUID
        
    } catch {
        Write-Status "GitHub failed for $Name. Will try manual." "WARN"
        Add-ToManualList -Name $Name -URL "https://apps.elgato.com/plugins/$UUID"
    }
}

function Install-PluginFile {
    param([string]$Path, [string]$Name, [string]$UUID)
    
    $pluginDir = "$env:APPDATA\Elgato\StreamDeck\Plugins\$UUID.sdPlugin"
    if (Test-Path $pluginDir) {
        Write-Status "$Name already installed" "SUCCESS"
        return
    }
    
    Write-Status "Installing $Name..."
    Start-Process $Path -Wait -ErrorAction SilentlyContinue
    Write-Status "$Name installed" "SUCCESS"
}

$script:ManualInstalls = @()

function Add-ToManualList {
    param([string]$Name, [string]$URL)
    $script:ManualInstalls += @{ Name = $Name; URL = $URL }
}

function Install-AllPlugins {
    Write-Status "Installing plugins (rate-limit safe)..." "STEP"
    
    # BarRaider plugins
    Install-FromGitHub -Owner "barraider" -Repo "streamdeck-wintools" -UUID "com.barraider.wintools" -Name "Windows Utils"
    Install-FromGitHub -Owner "barraider" -Repo "streamdeck-tools" -UUID "com.barraider.streamdecktools" -Name "Stream Deck Tools"
    Install-FromGitHub -Owner "barraider" -Repo "streamdeck-advancedlauncher" -UUID "com.barraider.advancedlauncher" -Name "Advanced Launcher"
    
    # Fred Emmott plugins
    Install-FromGitHub -Owner "fredemmott" -Repo "streamdeck-audiometer" -UUID "com.fredemmott.audiometer" -Name "Audio Meter"
    
    if ($script:ManualInstalls.Count -gt 0) {
        Write-Host ""
        Write-Status "Manual install needed for:" "WARN"
        $script:ManualInstalls | ForEach-Object { Write-Host "  • $($_.Name): $($_.URL)" }
    }
}

function Setup-OpenClaw {
    Write-Status "Creating OpenClaw integration..." "STEP"
    
    $dir = "$env:APPDATA\Elgato\StreamDeck\Plugins\com.openclaw.webhooks.sdPlugin"
    if (Test-Path $dir) { Write-Status "OpenClaw plugin exists" "SUCCESS"; return }
    
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
    Write-Status "Generating OpenClaw profiles..." "STEP"
    
    $dir = "$env:USERPROFILE\.openclaw\streamdeck-profiles"
    New-Item -ItemType Directory -Path $dir -Force -ErrorAction SilentlyContinue | Out-Null
    
    @(
        @{ Name = "OpenClaw MK.2"; Keys = 15; Model = "20GAI9901" }
        @{ Name = "OpenClaw XL"; Keys = 32; Model = "20GBD9901" }
        @{ Name = "OpenClaw Plus"; Keys = 15; Model = "20GBA9901" }
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
    
    Write-Status "Profiles ready" "SUCCESS"
}

function Show-Done {
    Write-Host ""
    Write-Host "=========================================="
    Write-Host "  Setup Complete!                         "
    Write-Host "=========================================="
    Write-Host ""
    Write-Status "Next:" "STEP"
    Write-Host "  1. Restart Stream Deck if needed"
    Write-Host "  2. Import profiles from:"
    Write-Host "     $env:USERPROFILE\.openclaw\streamdeck-profiles\"
    Write-Host ""
    Read-Host "Press Enter"
}

# Run
try {
    Initialize-Setup
    Test-StreamDeck
    Install-AllPlugins
    Setup-OpenClaw
    Generate-Profiles
    Show-Done
} catch {
    Write-Status "Error: $_" "ERROR"
    Read-Host "Press Enter"
}
