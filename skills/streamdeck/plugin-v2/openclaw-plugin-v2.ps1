# OpenClaw Stream Deck Plugin v2.0 - Enhanced Edition
# Premium features included

param(
    [Parameter(Mandatory=$true)]
    [string]$Action,
    
    [string]$GatewayUrl = "http://127.0.0.1:18790",
    [string]$Settings = "{}",
    [string]$Event = "keyUp",
    [string]$Context = ""
)

$ErrorActionPreference = "Stop"

# Feature 1: Smart Context Detection
$ActiveWindow = (Get-Process | Where-Object {$_.MainWindowTitle -ne ""} | 
    Select-Object -First 1).MainWindowTitle

$ContextActions = switch -Wildcard ($ActiveWindow) {
    "*VS Code*" { @("spawn", "coding", "status") }
    "*Discord*" { @("message", "tts", "status") }
    "*Chrome*" { @("websearch", "browser", "session") }
    "*OBS*" { @("status", "nodes", "subagents") }
    default { @("spawn", "status", "tts", "models") }
}

# Feature 2: Dynamic Status Updates
function Update-StreamDeckKey {
    param([string]$Title, [string]$Image, [int]$State = 0)
    
    $update = @{
        event = "setTitle"
        context = $Context
        payload = @{ title = $Title }
    } | ConvertTo-Json -Compress
    
    Write-Host $update
}

# Feature 3: Multi-Step Macro Engine
function Invoke-Macro {
    param([array]$Steps)
    
    $results = @()
    foreach ($step in $Steps) {
        $result = Invoke-OpenClawAction -Action $step.Action -Params $step.Params
        $results += $result
        
        if (-not $result.Success -and $step.StopOnError) {
            return @{ Success = $false; Step = $step.Name; Error = $result.Error }
        }
        
        if ($step.Delay) {
            Start-Sleep -Milliseconds $step.Delay
        }
    }
    
    return @{ Success = $true; Results = $results }
}

# Feature 4: Live System Dashboard
function Get-SystemStatus {
    $cpu = (Get-Counter '\Processor(_Total)\% Processor Time').CounterSamples[0].CookedValue
    $mem = Get-WmiObject -Class Win32_OperatingSystem | 
        ForEach-Object {[math]::Round(($_.TotalVisibleMemorySize - $_.FreePhysicalMemory) / $_.TotalVisibleMemorySize * 100, 1)}
    
    return @{ CPU = [math]::Round($cpu, 1); Memory = $mem }
}

# Feature 5: Smart Error Recovery
function Invoke-WithRetry {
    param([scriptblock]$ScriptBlock, [int]$MaxRetries = 3)
    
    $attempt = 0
    do {
        try {
            return & $ScriptBlock
        } catch {
            $attempt++
            if ($attempt -ge $MaxRetries) { throw }
            Start-Sleep -Milliseconds 500
        }
    } while ($attempt -lt $MaxRetries)
}

# Main action handler
function Invoke-OpenClawAction {
    param([string]$ActionName, [hashtable]$Params = @{})
    
    $endpoints = @{
        "tts" = "tts.toggle"
        "spawn" = "spawn"
        "status" = "status"
        "models" = "models"
        "subagents" = "subagents"
        "nodes" = "nodes.status"
        "restart" = "gateway.restart"
        "config" = "config.get"
        "session" = "session.status"
        "websearch" = "web.search"
        "memory" = "memory.search"
        "coding" = "spawn"
        "message" = "message.send"
        "browser" = "browser.open"
    }
    
    try {
        $endpoint = $endpoints[$ActionName]
        $body = $Params | ConvertTo-Json
        $response = Invoke-RestMethod -Uri "$GatewayUrl/$endpoint" -Method Post -Body $body -ContentType "application/json" -TimeoutSec 5
        return @{ Success = $true; Data = $response }
    } catch {
        return @{ Success = $false; Error = $_.Exception.Message }
    }
}

# Execute based on action
switch ($Action) {
    "smart" {
        # Feature: Context-aware buttons
        $suggested = $ContextActions | Select-Object -First 1
        Update-StreamDeckKey -Title "Smart: $suggested"
    }
    
    "dashboard" {
        # Feature: Live system stats
        $stats = Get-SystemStatus
        Update-StreamDeckKey -Title "CPU: $($stats.CPU)%"
    }
    
    "macro" {
        # Feature: Multi-step automation
        $macroSteps = @(
            @{ Name = "Check"; Action = "status"; StopOnError = $true }
            @{ Name = "Spawn"; Action = "spawn"; Params = @{ task = "Automated task" }; Delay = 1000 }
            @{ Name = "Verify"; Action = "subagents" }
        )
        Invoke-Macro -Steps $macroSteps
    }
    
    default {
        # Standard actions with retry
        Invoke-WithRetry -ScriptBlock {
            Invoke-OpenClawAction -ActionName $Action -Params ($Settings | ConvertFrom-Json)
        }
    }
}

# Always return status
@{ Status = "OK"; Action = $Action; Timestamp = Get-Date -Format "o" } | ConvertTo-Json
