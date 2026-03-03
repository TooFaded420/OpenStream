# OpenClaw Cross-Device Network Setup
# Windows ↔ Mac Mini bidirectional connection

# Network Configuration
$NetworkConfig = @{
    Windows = @{
        Name = "Origin-PC"
        IP = "192.168.1.100"      # Your Windows PC IP
        Port = 18790
        Token = "oc_gw_windows_token_$(-join ((48..57) + (65..90) + (97..122) | Get-Random -Count 16 | ForEach-Object { [char]$_ }))"
        Device = "Windows Desktop"
        Role = "primary"
    }
    Mac = @{
        Name = "Mac-Mini"
        IP = "192.168.1.50"       # Your Mac Mini IP
        Port = 18790
        Token = "oc_gw_mac_token_$(-join ((48..57) + (65..90) + (97..122) | Get-Random -Count 16 | ForEach-Object { [char]$_ }))"
        Device = "Mac Mini M2"
        Role = "secondary"
    }
}

# Self-Healing Configuration
$SelfHealing = @{
    Enabled = $true
    HealthCheckInterval = 30          # seconds
    FailoverThreshold = 3             # failed checks before failover
    AutoRestart = $true
    SyncSessions = $true
    CrossDeviceAgents = $true
}

# Cross-Device Agent Pool
$AgentPool = @{
    "windows-agents" = @{
        Device = "Origin-PC"
        MaxAgents = 5
        CurrentAgents = 0
        Tasks = @()
    }
    "mac-agents" = @{
        Device = "Mac-Mini"
        MaxAgents = 5
        CurrentAgents = 0
        Tasks = @()
    }
}

# Network Discovery
discover-devices.ps1
$DiscoveredDevices = @()

function Find-OpenClawDevices {
    param([string]$Subnet = "192.168.1")
    
    Write-Host "Scanning network for OpenClaw devices..." -ForegroundColor Cyan
    
    1..254 | ForEach-Object -Parallel {
        $ip = "$using:Subnet.$_"
        try {
            $response = Invoke-RestMethod -Uri "http://$ip`:18790/status" -Method Get -TimeoutSec 2
            [PSCustomObject]@{
                IP = $ip
                Name = $response.device
                Version = $response.version
                Status = "Online"
            }
        } catch { }
    } -ThrottleLimit 50
}

# Health Monitoring
function Test-DeviceHealth {
    param([string]$DeviceName)
    
    $device = $NetworkConfig[$DeviceName]
    $failures = 0
    
    while ($failures -lt $SelfHealing.FailoverThreshold) {
        try {
            $response = Invoke-RestMethod -Uri "http://$($device.IP):$($device.Port)/status" -Method Get -TimeoutSec 5
            return @{ Healthy = $true; Latency = $response.latency }
        } catch {
            $failures++
            Write-Host "$DeviceName health check failed ($failures/$($SelfHealing.FailoverThreshold))" -ForegroundColor Yellow
            Start-Sleep 5
        }
    }
    
    return @{ Healthy = $false; Failures = $failures }
}

# Self-Healing Loop
function Start-SelfHealing {
    Write-Host "Starting self-healing monitor..." -ForegroundColor Green
    
    while ($true) {
        # Check Windows
        $windowsHealth = Test-DeviceHealth -DeviceName "Windows"
        if (-not $windowsHealth.Healthy -and $SelfHealing.AutoRestart) {
            Write-Host "Windows OpenClaw unhealthy! Attempting recovery..." -ForegroundColor Red
            # Try to restart Windows service
            Invoke-Command -ScriptBlock { openclaw gateway restart }
        }
        
        # Check Mac
        $macHealth = Test-DeviceHealth -DeviceName "Mac"
        if (-not $macHealth.Healthy -and $SelfHealing.AutoRestart) {
            Write-Host "Mac OpenClaw unhealthy! Attempting recovery..." -ForegroundColor Red
            # Send restart command to Mac
            Invoke-RestMethod -Uri "http://$($NetworkConfig.Mac.IP):$($NetworkConfig.Mac.Port)/gateway.restart" -Method Post
        }
        
        # Sync sessions if both healthy
        if ($windowsHealth.Healthy -and $macHealth.Healthy -and $SelfHealing.SyncSessions) {
            Sync-CrossDeviceSessions
        }
        
        Start-Sleep $SelfHealing.HealthCheckInterval
    }
}

# Cross-Device Session Sync
function Sync-CrossDeviceSessions {
    $windowsSessions = Invoke-RestMethod -Uri "http://$($NetworkConfig.Windows.IP):$($NetworkConfig.Windows.Port)/sessions.list"
    $macSessions = Invoke-RestMethod -Uri "http://$($NetworkConfig.Mac.IP):$($NetworkConfig.Mac.Port)/sessions.list"
    
    # Sync to both devices
    Invoke-RestMethod -Uri "http://$($NetworkConfig.Windows.IP):$($NetworkConfig.Windows.Port)/sessions.sync" -Method Post -Body (@{ sessions = $macSessions } | ConvertTo-Json)
    Invoke-RestMethod -Uri "http://$($NetworkConfig.Mac.IP):$($NetworkConfig.Mac.Port)/sessions.sync" -Method Post -Body (@{ sessions = $windowsSessions } | ConvertTo-Json)
}

# Agent Load Balancing
function Distribute-AgentTask {
    param([string]$Task, [hashtable]$Parameters)
    
    # Find least loaded device
    $windowsLoad = (Invoke-RestMethod -Uri "http://$($NetworkConfig.Windows.IP):$($NetworkConfig.Windows.Port)/agents.count").count
    $macLoad = (Invoke-RestMethod -Uri "http://$($NetworkConfig.Mac.IP):$($NetworkConfig.Mac.Port)/agents.count").count
    
    $targetDevice = if ($windowsLoad -le $macLoad) { "Windows" } else { "Mac" }
    
    Write-Host "Distributing task to $targetDevice (load: Windows=$windowsLoad, Mac=$macLoad)" -ForegroundColor Cyan
    
    # Spawn agent on target device
    $targetUrl = $NetworkConfig[$targetDevice].IP + ":" + $NetworkConfig[$targetDevice].Port
    return Invoke-RestMethod -Uri "http://$targetUrl/spawn" -Method Post -Body (@{ task = $Task; parameters = $Parameters } | ConvertTo-Json)
}

# Failover Handler
function Invoke-Failover {
    param([string]$FromDevice, [string]$ToDevice)
    
    Write-Host "FAILOVER: $FromDevice → $ToDevice" -ForegroundColor Magenta
    
    # Transfer active sessions
    $sessions = Invoke-RestMethod -Uri "http://$($NetworkConfig[$FromDevice].IP):$($NetworkConfig[$FromDevice].Port)/sessions.export"
    Invoke-RestMethod -Uri "http://$($NetworkConfig[$ToDevice].IP):$($NetworkConfig[$ToDevice].Port)/sessions.import" -Method Post -Body (@{ sessions = $sessions } | ConvertTo-Json)
    
    # Notify user
    Invoke-RestMethod -Uri "http://$($NetworkConfig[$ToDevice].IP):$($NetworkConfig[$ToDevice].Port)/message.send" -Method Post -Body (@{ 
        text = "Failover complete: $FromDevice → $ToDevice. All sessions transferred."
        channel = "telegram"
    } | ConvertTo-Json)
}

# Export configuration
$NetworkConfig | ConvertTo-Json -Depth 5 | Out-File "$env:USERPROFILE\.openclaw\cross-device-config.json"
Write-Host "Cross-device configuration saved!" -ForegroundColor Green
Write-Host ""
Write-Host "Windows Token: $($NetworkConfig.Windows.Token)" -ForegroundColor Cyan
Write-Host "Mac Token: $($NetworkConfig.Mac.Token)" -ForegroundColor Cyan
Write-Host ""
Write-Host "To start self-healing, run: Start-SelfHealing" -ForegroundColor Yellow
