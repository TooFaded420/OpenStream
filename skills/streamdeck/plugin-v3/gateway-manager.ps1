# OpenClaw Multi-Gateway Network Manager
# Controls multiple OpenClaw instances across your network

param(
    [string]$Command = "list",  # list, status, switch, broadcast, sync
    [string]$Settings = "{}"
)

# Gateway registry - supports multiple devices on network
$Global:GatewayRegistry = @{
    # Local gateways
    "local-pc" = @{
        Name = "Main PC"
        URL = "http://localhost:18790"
        Device = "Windows Desktop"
        Location = "Office"
        Priority = 1
        Status = "unknown"
        LastSeen = $null
    }
    
    # Network gateways (examples - user configures these)
    "mac-mini" = @{
        Name = "Mac Mini"
        URL = "http://192.168.1.50:18790"
        Device = "Mac Mini M2"
        Location = "Living Room"
        Priority = 2
        Status = "unknown"
        LastSeen = $null
    }
    
    "laptop" = @{
        Name = "Laptop"
        URL = "http://192.168.1.75:18790"
        Device = "MacBook Pro"
        Location = "Mobile"
        Priority = 3
        Status = "unknown"
        LastSeen = $null
    }
    
    "server" = @{
        Name = "Home Server"
        URL = "http://192.168.1.10:18790"
        Device = "Linux Server"
        Location = "Basement"
        Priority = 4
        Status = "unknown"
        LastSeen = $null
    }
}

$Global:ActiveGateway = "local-pc"
$Global:AutoFailover = $true

function Test-GatewayHealth {
    param([string]$GatewayKey)
    
    $gw = $Global:GatewayRegistry[$GatewayKey]
    if (-not $gw) { return @{ Online = $false; Reason = "Gateway not configured" } }
    
    # Validate and fix URL
    $url = $gw.URL
    if (-not $url -match "^https?://") {
        $url = "http://$url"
        $gw.URL = $url
    }
    
    try {
        $start = Get-Date
        $response = Invoke-RestMethod -Uri "$url/status" -Method Get -TimeoutSec 5
        $latency = ((Get-Date) - $start).TotalMilliseconds
        
        $gw.Status = "online"
        $gw.LastSeen = Get-Date
        
        return @{
            Online = $true
            Latency = [math]::Round($latency, 0)
            Version = $response.version
            Model = $response.model
            Sessions = $response.sessions
        }
    } catch {
        $gw.Status = "offline"
        $errorMsg = switch -Regex ($_.Exception.Message) {
            "connection.*refused" { "Gateway offline - check if OpenClaw is running" }
            "timeout" { "Network timeout - check network connection" }
            "name.*resolution" { "DNS error - check IP address" }
            default { "Connection failed - $($_.Exception.Message.Split(':')[0])" }
        }
        return @{ Online = $false; Reason = $errorMsg }
    }
}

function Get-AllGatewayStatus {
    $results = @{}
    foreach ($key in $Global:GatewayRegistry.Keys) {
        $results[$key] = Test-GatewayHealth -GatewayKey $key
    }
    return $results
}

function Switch-ToBestGateway {
    $statuses = Get-AllGatewayStatus
    
    # Find online gateways sorted by priority
    $online = $statuses.GetEnumerator() | 
        Where-Object { $_.Value.Online } |
        Sort-Object { $Global:GatewayRegistry[$_.Key].Priority }
    
    if ($online.Count -eq 0) {
        return @{ Success = $false; Error = "No gateways available" }
    }
    
    $best = $online | Select-Object -First 1
    $Global:ActiveGateway = $best.Key
    
    return @{
        Success = $true
        Gateway = $best.Key
        URL = $Global:GatewayRegistry[$best.Key].URL
        Latency = $best.Value.Latency
    }
}

function Send-CommandToAll {
    param([string]$Endpoint, [hashtable]$Body = @{})
    
    $results = @{}
    $successCount = 0
    
    foreach ($key in $Global:GatewayRegistry.Keys) {
        $gw = $Global:GatewayRegistry[$key]
        
        try {
            $jsonBody = $Body | ConvertTo-Json
            $response = Invoke-RestMethod -Uri "$($gw.URL)$Endpoint" -Method Post -Body $jsonBody -ContentType "application/json" -TimeoutSec 5
            $results[$key] = @{ Success = $true; Data = $response }
            $successCount++
        } catch {
            $results[$key] = @{ Success = $false; Error = $_.Exception.Message }
        }
    }
    
    return @{
        Results = $results
        SuccessCount = $successCount
        TotalCount = $Global:GatewayRegistry.Count
    }
}

function Sync-Sessions {
    # Sync session state between gateways
    $primary = $Global:GatewayRegistry[$Global:ActiveGateway]
    
    try {
        # Get sessions from primary
        $sessions = Invoke-RestMethod -Uri "$($primary.URL)/sessions" -Method Get -TimeoutSec 5
        
        # Broadcast to others
        $syncResults = @{}
        foreach ($key in $Global:GatewayRegistry.Keys) {
            if ($key -eq $Global:ActiveGateway) { continue }
            
            $gw = $Global:GatewayRegistry[$key]
            try {
                Invoke-RestMethod -Uri "$($gw.URL)/sessions.sync" -Method Post -Body (@{ sessions = $sessions } | ConvertTo-Json) -ContentType "application/json" -TimeoutSec 5 | Out-Null
                $syncResults[$key] = "Synced"
            } catch {
                $syncResults[$key] = "Failed: $_"
            }
        }
        
        return @{ Success = $true; SyncedTo = $syncResults }
    } catch {
        return @{ Success = $false; Error = $_.Exception.Message }
    }
}

# Main execution based on command
switch ($Command) {
    "list" {
        Write-Host "Available Gateways:`n" -ForegroundColor Cyan
        foreach ($key in ($Global:GatewayRegistry.Keys | Sort-Object { $Global:GatewayRegistry[$_].Priority })) {
            $gw = $Global:GatewayRegistry[$key]
            $status = Test-GatewayHealth -GatewayKey $key
            $indicator = if ($key -eq $Global:ActiveGateway) { "→ " } else { "  " }
            $online = if ($status.Online) { "🟢" } else { "🔴" }
            Write-Host "$indicator$online $($gw.Name)" -NoNewline
            Write-Host " ($($gw.URL))" -ForegroundColor Gray -NoNewline
            if ($status.Online) {
                Write-Host " - $($status.Latency)ms" -ForegroundColor Green
            } else {
                Write-Host " - $($status.Reason)" -ForegroundColor Red
            }
        }
    }
    
    "status" {
        $statuses = Get-AllGatewayStatus
        Write-Host "Gateway Health Check:`n" -ForegroundColor Cyan
        
        $onlineCount = ($statuses.Values | Where-Object { $_.Online }).Count
        Write-Host "Online: $onlineCount/$($statuses.Count) gateways`n" -ForegroundColor Green
        
        $statuses.GetEnumerator() | ForEach-Object {
            $name = $Global:GatewayRegistry[$_.Key].Name
            if ($_.Value.Online) {
                Write-Host "✓ $name - $($_.Value.Latency)ms - v$($_.Value.Version)" -ForegroundColor Green
            } else {
                Write-Host "✗ $name - $($_.Value.Reason)" -ForegroundColor Red
            }
        }
    }
    
    "switch" {
        $result = Switch-ToBestGateway
        if ($result.Success) {
            Write-Host "Switched to: $($result.Gateway)" -ForegroundColor Green
            Write-Host "Latency: $($result.Latency)ms" -ForegroundColor Cyan
        } else {
            Write-Host "Failed: $($result.Error)" -ForegroundColor Red
        }
    }
    
    "broadcast" {
        Write-Host "Broadcasting to all gateways..." -ForegroundColor Cyan
        $result = Send-CommandToAll -Endpoint "/message.send" -Body @{ text = "Broadcast from Stream Deck"; channel = "all" }
        Write-Host "Success: $($result.SuccessCount)/$($result.TotalCount) gateways" -ForegroundColor $(if($result.SuccessCount -eq $result.TotalCount){"Green"}else{"Yellow"})
    }
    
    "sync" {
        Write-Host "Syncing sessions across gateways..." -ForegroundColor Cyan
        $result = Sync-Sessions
        if ($result.Success) {
            Write-Host "✓ Synced successfully" -ForegroundColor Green
            $result.SyncedTo.GetEnumerator() | ForEach-Object {
                Write-Host "  $($_.Key): $($_.Value)"
            }
        } else {
            Write-Host "✗ Sync failed: $($result.Error)" -ForegroundColor Red
        }
    }
    
    default {
        Write-Host "Unknown command: $Command" -ForegroundColor Red
        Write-Host "Usage: list | status | switch | broadcast | sync"
    }
}
