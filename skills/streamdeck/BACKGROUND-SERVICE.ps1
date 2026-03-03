# OpenClaw Stream Deck Background Service
# Runs continuously to sync, update, and monitor Stream Deck
# Register with: .\BACKGROUND-SERVICE.ps1 -Register

param(
    [switch]$Register,
    [switch]$Unregister,
    [switch]$RunOnce
)

$ServiceName = "OpenClawStreamDeckManager"
$LogPath = "$env:USERPROFILE\.openclaw\logs\streamdeck-service.log"

function Write-Log {
    param($Message, $Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "$timestamp [$Level] $Message"
    Add-Content -Path $LogPath -Value $logEntry -ErrorAction SilentlyContinue
    if ($Level -eq "ERROR") { Write-Host $logEntry -ForegroundColor Red }
}

function Register-Service {
    # Create scheduled task to run this script every 5 minutes
    $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-File `"$PSCommandPath`" -RunOnce"
    $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(1) -RepetitionInterval (New-TimeSpan -Minutes 5) -RepetitionDuration (New-TimeSpan -Days 9999)
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
    
    try {
        Register-ScheduledTask -TaskName $ServiceName -Action $action -Trigger $trigger -Settings $settings -Force
        Write-Host "Service registered successfully!" -ForegroundColor Green
        Write-Host "Running every 5 minutes in background." -ForegroundColor Gray
    } catch {
        Write-Host "Failed to register: $_" -ForegroundColor Red
    }
}

function Unregister-Service {
    try {
        Unregister-ScheduledTask -TaskName $ServiceName -Confirm:$false
        Write-Host "Service unregistered." -ForegroundColor Green
    } catch {
        Write-Host "Service not found or already unregistered." -ForegroundColor Yellow
    }
}

function Sync-StreamDeck {
    Write-Log "Starting sync cycle..."
    
    # Check if Stream Deck is running
    $sdProcess = Get-Process "StreamDeck" -ErrorAction SilentlyContinue
    if (-not $sdProcess) {
        Write-Log "Stream Deck not running, attempting restart..." "WARN"
        $sdPaths = @(
            "$env:ProgramFiles\Elgato\StreamDeck\StreamDeck.exe",
            "$env:LOCALAPPDATA\Programs\Elgato\StreamDeck\StreamDeck.exe"
        )
        foreach ($path in $sdPaths) {
            if (Test-Path $path) {
                Start-Process $path
                Write-Log "Stream Deck restarted"
                Start-Sleep 5
                break
            }
        }
    }
    
    # Check gateway health
    try {
        $response = Invoke-RestMethod -Uri "http://127.0.0.1:18790/status" -Method Get -TimeoutSec 5
        Write-Log "Gateway healthy: $($response.sessions) sessions"
    } catch {
        Write-Log "Gateway unreachable" "WARN"
        # Could auto-restart gateway here
    }
    
    # Check for updates
    $configPath = "$env:USERPROFILE\.openclaw\streamdeck-plugin\config.json"
    if (Test-Path $configPath) {
        $config = Get-Content $configPath | ConvertFrom-Json
        # Check if config needs updating
    }
    
    Write-Log "Sync cycle complete"
}

function Monitor-Health {
    # Continuous health monitoring
    $healthChecks = @{
        StreamDeckRunning = (Get-Process "StreamDeck" -ErrorAction SilentlyContinue) -ne $null
        PluginInstalled = Test-Path "$env:APPDATA\Elgato\StreamDeck\Plugins\com.openclaw.webhooks.sdPlugin"
        GatewayReachable = $false
        ActiveProfile = "Unknown"
    }
    
    try {
        $response = Invoke-RestMethod -Uri "http://127.0.0.1:18790/status" -Method Get -TimeoutSec 2
        $healthChecks.GatewayReachable = $true
    } catch {}
    
    # Save health status
    $healthPath = "$env:USERPROFILE\.openclaw\streamdeck-health.json"
    $healthChecks | ConvertTo-Json | Out-File $healthPath -Encoding UTF8
    
    return $healthChecks
}

# Main execution
if ($Register) {
    Register-Service
    return
}

if ($Unregister) {
    Unregister-Service
    return
}

# Run sync
Sync-StreamDeck

# Run health check
$health = Monitor-Health

# Output if running interactively
if (-not $RunOnce) {
    Write-Host "Stream Deck Manager Status:" -ForegroundColor Cyan
    Write-Host "  Stream Deck: $(if($health.StreamDeckRunning){'Running'}else{'Not running'})"
    Write-Host "  Plugin: $(if($health.PluginInstalled){'Installed'}else{'Not installed'})"
    Write-Host "  Gateway: $(if($health.GatewayReachable){'Reachable'}else{'Unreachable'})"
}

Write-Log "Service cycle complete"