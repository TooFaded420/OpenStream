# Stream Deck Auto-Setup for OpenClaw
# One-click installation for Stream Deck + OpenClaw integration
# Run as: powershell -ExecutionPolicy Bypass -File auto-setup.ps1

param([switch]$Silent)

$script:Version = "1.0.0"
$script:SetupDir = "$env:USERPROFILE\.openclaw\streamdeck-setup"
$script:LogFile = "$script:SetupDir\setup.log"

function Write-Status {
    param([string]$Message, [string]$Type = "INFO")
    $timestamp = Get-Date -Format "HH:mm:ss"
    $prefix = switch ($Type) {
        "SUCCESS" { "[SUCCESS]" }
        "ERROR" { "[ERROR]" }
        "WARN" { "[WARN]" }
        "STEP" { "[STEP]" }
        default { "[INFO]" }
    }
    $output = "$timestamp $prefix $Message"
    Write-Host $output
    if (-not $Silent) {
        $output | Out-File $LogFile -Append -ErrorAction SilentlyContinue
    }
}

function Initialize-Setup {
    Write-Status "Starting Stream Deck Auto-Setup v$script:Version" "STEP"
    
    if (-not (Test-Path $script:SetupDir)) {
        New-Item -ItemType Directory -Path $script:SetupDir -Force | Out-Null
    }
    
    if (Test-Path $LogFile) {
        Remove-Item $LogFile -Force -ErrorAction SilentlyContinue
    }
    
    Write-Host ""
    Write-Host "========================================"
    Write-Host "  Stream Deck + OpenClaw Auto-Setup   "
    Write-Host "  One-click AI command center setup     "
    Write-Host "========================================"
    Write-Host ""
}

function Test-StreamDeckSoftware {
    Write-Status "Checking Stream Deck software..." "STEP"
    
    $sdPaths = @(
        "$env:ProgramFiles\Elgato\StreamDeck\StreamDeck.exe"
        "$env:LOCALAPPDATA\Programs\Elgato\StreamDeck\StreamDeck.exe"
    )
    
    $found = $false
    foreach ($path in $sdPaths) {
        if (Test-Path $path) {
            Write-Status "Found Stream Deck at: $path" "SUCCESS"
            $found = $true
            break
        }
    }
    
    if (-not $found) {
        Write-Status "Stream Deck software not found!" "ERROR"
        Write-Status "Please install from elgato.com" "ERROR"
        Read-Host "Press Enter to exit"
        exit 1
    }
    
    $process = Get-Process "StreamDeck" -ErrorAction SilentlyContinue
    if (-not $process) {
        Write-Status "Stream Deck not running. Starting..." "WARN"
        Start-Process "$env:ProgramFiles\Elgato\StreamDeck\StreamDeck.exe" -ErrorAction SilentlyContinue
        Start-Sleep 5
    }
}

function Download-Plugin {
    param([string]$Owner, [string]$Repo, [string]$UUID, [string]$Name)
    
    Write-Status "Installing $Name..." "STEP"
    
    $pluginDir = "$env:APPDATA\Elgato\StreamDeck\Plugins\$UUID.sdPlugin"
    if (Test-Path $pluginDir) {
        Write-Status "$Name already installed" "SUCCESS"
        return
    }
    
    try {
        $apiUrl = "https://api.github.com/repos/$Owner/$Repo/releases/latest"
        Write-Status "Fetching release info..."
        
        $release = Invoke-RestMethod -Uri $apiUrl -Headers @{ "User-Agent" = "OpenClaw" } -ErrorAction Stop
        $asset = $release.assets | Where-Object { $_.name -like "*.streamDeckPlugin" } | Select-Object -First 1
        
        if (-not $asset) {
            Write-Status "No plugin file found. Manual install required." "WARN"
            Write-Status "  Visit: https://apps.elgato.com/plugins/$UUID" "INFO"
            return
        }
        
        $downloadPath = "$script:SetupDir\$UUID.streamDeckPlugin"
        Write-Status "Downloading..."
        Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $downloadPath -Headers @{ "User-Agent" = "OpenClaw" } -ErrorAction Stop
        
        Write-Status "Installing (Stream Deck will open)..." "STEP"
        Start-Process $downloadPath -Wait -ErrorAction SilentlyContinue
        
        Remove-Item $downloadPath -Force -ErrorAction SilentlyContinue
        Write-Status "$Name installed" "SUCCESS"
        
    } catch {
        Write-Status "Could not auto-install $Name" "WARN"
        Write-Status "  Manual: https://apps.elgato.com/plugins/$UUID" "INFO"
    }
}

function Install-Plugins {
    Write-Status "Installing plugins..." "STEP"
    
    Download-Plugin -Owner "barraider" -Repo "streamdeck-wintools" -UUID "com.barraider.wintools" -Name "BarRaider Windows Utils"
    Download-Plugin -Owner "barraider" -Repo "streamdeck-tools" -UUID "com.barraider.streamdecktools" -Name "BarRaider Stream Deck Tools"
    Download-Plugin -Owner "barraider" -Repo "streamdeck-advancedlauncher" -UUID "com.barraider.advancedlauncher" -Name "Advanced Launcher"
    Download-Plugin -Owner "fredemmott" -Repo "streamdeck-audiometer" -UUID "com.fredemmott.audiometer" -Name "Audio Meter"
}

function Setup-OpenClawIntegration {
    Write-Status "Setting up OpenClaw integration..." "STEP"
    
    $pluginDir = "$env:APPDATA\Elgato\StreamDeck\Plugins\com.openclaw.webhooks.sdPlugin"
    if (Test-Path $pluginDir) {
        Write-Status "OpenClaw plugin exists" "SUCCESS"
        return
    }
    
    New-Item -ItemType Directory -Path $pluginDir -Force | Out-Null
    
    $manifest = @{ 
        Actions = @( 
            @{ UUID = "com.openclaw.tts"; Name = "OpenClaw TTS"; Icon = "tts"; States = @( @{ Image = "tts"; Title = "TTS" } ) }
            @{ UUID = "com.openclaw.spawn"; Name = "OpenClaw Spawn"; Icon = "spawn"; States = @( @{ Image = "spawn"; Title = "Spawn" } ) }
            @{ UUID = "com.openclaw.status"; Name = "OpenClaw Status"; Icon = "status"; States = @( @{ Image = "status"; Title = "Status" } ) }
        )
        Category = "OpenClaw"
        Description = "Control OpenClaw from Stream Deck"
        Name = "OpenClaw Webhooks"
        UUID = "com.openclaw.webhooks"
        Version = "1.0"
        Author = "OpenClaw"
    }
    
    $manifest | ConvertTo-Json -Depth 5 | Out-File "$pluginDir\manifest.json"
    
    $webhookScript = 'param([string]$Action, [string]$Data)' + "`n" + '$gateway = "http://127.0.0.1:18790"' + "`n" + 'switch ($Action) {' + "`n" + '    "tts" { Invoke-RestMethod -Uri "$gateway/tts" -Method Post -Body (@{text=$Data} | ConvertTo-Json) -ContentType "application/json" }' + "`n" + '    "spawn" { Invoke-RestMethod -Uri "$gateway/spawn" -Method Post -Body (@{task=$Data} | ConvertTo-Json) -ContentType "application/json" }' + "`n" + '    "status" { Invoke-RestMethod -Uri "$gateway/status" -Method Get }' + "`n" + '}'
    
    $webhookScript | Out-File "$script:SetupDir\webhook-handler.ps1"
    
    Write-Status "OpenClaw plugin created" "SUCCESS"
}

function Generate-Profiles {
    Write-Status "Generating profiles..." "STEP"
    
    $profileDir = "$env:USERPROFILE\.openclaw\streamdeck-profiles"
    New-Item -ItemType Directory -Path $profileDir -Force -ErrorAction SilentlyContinue | Out-Null
    
    $profiles = @(
        @{ Name = "OpenClaw Control (MK.2)"; Keys = 15; Model = "20GAI9901" }
        @{ Name = "OpenClaw Command Center (XL)"; Keys = 32; Model = "20GBD9901" }
        @{ Name = "OpenClaw Studio (Plus)"; Keys = 15; Model = "20GBA9901" }
    )
    
    foreach ($prof in $profiles) {
        $profileId = [Guid]::NewGuid().ToString().ToUpper()
        $profilePath = "$profileDir\$profileId.sdProfile"
        
        New-Item -ItemType Directory -Path $profilePath -Force | Out-Null
        New-Item -ItemType Directory -Path "$profilePath\Profiles" -Force | Out-Null
        New-Item -ItemType Directory -Path "$profilePath\Images" -Force | Out-Null
        
        $pageId = [Guid]::NewGuid().ToString()
        $manifest = @{
            Device = @{ Model = $prof.Model; UUID = "generated-$profileId" }
            Name = $prof.Name
            Pages = @{ Current = $pageId; Default = $pageId; Pages = @($pageId) }
            Version = "2.0"
        }
        $manifest | ConvertTo-Json -Depth 5 | Out-File "$profilePath\manifest.json"
        
        $pageData = @{ Controller = ""; Actions = @() }
        $pageData | ConvertTo-Json -Depth 5 | Out-File "$profilePath\Profiles\$pageId.json"
        
        Write-Status "  Created: $($prof.Name)" "SUCCESS"
    }
    
    Write-Status "Profiles ready in: $profileDir" "SUCCESS"
}

function Show-Done {
    Write-Host ""
    Write-Host "========================================"
    Write-Host "  Setup Complete!                       "
    Write-Host "========================================"
    Write-Host ""
    Write-Status "Next steps:" "STEP"
    Write-Host ""
    Write-Host "1. Restart Stream Deck (if plugins installed)"
    Write-Host "2. Open Stream Deck -> Profile -> Import"
    Write-Host "3. Select profiles from:"
    Write-Host "   $env:USERPROFILE\.openclaw\streamdeck-profiles\"
    Write-Host ""
    Write-Status "Log: $LogFile" "INFO"
    Write-Host ""
    Read-Host "Press Enter to exit"
}

# Main
try {
    Initialize-Setup
    Test-StreamDeckSoftware
    Install-Plugins
    Setup-OpenClawIntegration
    Generate-Profiles
    Show-Done
} catch {
    Write-Status "Error: $_" "ERROR"
    Read-Host "Press Enter to exit"
}
