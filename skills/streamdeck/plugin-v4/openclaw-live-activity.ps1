# OpenClaw Stream Deck Plugin v4.0
# Chowder-Powered Live Activity + Demo Mode + Identity Sync
# Features: WebSocket streaming, thinking steps, lifecycle states, demo mode

param(
    [Parameter(Mandatory=$true)]
    [string]$Action,
    
    [string]$Settings = "{}",
    [string]$Event = "keyUp",
    [string]$Context = ""
)

$ErrorActionPreference = "Stop"

# =============================================================================
# CONFIGURATION
# =============================================================================

$script:DemoMode = $false
$script:DemoModeAutoOff = $true
$script:GatewayURL = "http://127.0.0.1:18790"
$script:ReconnectAttempts = 5
$script:ReconnectDelay = 3
$script:PollingInterval = 500
$script:StateCooldownMs = 2000
$script:TimeoutSec = 10
$script:ContextId = $Context
$script:CurrentState = "idle"

# Demo content for testing without OpenClaw
$script:DemoSteps = @(
    @{ Text = "Considering options..."; Duration = 800 }
    @{ Text = "Checking memory..."; Duration = 600 }
    @{ Text = "Executing tool..."; Duration = 1200 }
    @{ Text = "Formatting response..."; Duration = 400 }
)

# =============================================================================
# IDENTITY SYNC
# =============================================================================

function Get-AgentIdentity {
    $id = @{
        Name = "OpenClaw"
        Emoji = "AI"
        Creature = "AI Assistant"
        Vibe = "Helpful"
    }
    
    $identityPath = "$env:USERPROFILE\.openclaw\workspace\IDENTITY.md"
    $soulPath = "$env:USERPROFILE\.openclaw\workspace\SOUL.md"
    
    if (Test-Path $identityPath) {
        $content = Get-Content $identityPath -Raw -ErrorAction SilentlyContinue
        if ($content -match "(?m)^[-*]\s*\*\*Name:\*\*\s*(.+)$") {
            $id.Name = $Matches[1].Trim()
        }
        if ($content -match "(?m)^[-*]\s*\*\*Emoji:\*\*\s*(.+)$") {
            $id.Emoji = $Matches[1].Trim()
        }
        if ($content -match "(?m)^[-*]\s*\*\*Creature:\*\*\s*(.+)$") {
            $id.Creature = $Matches[1].Trim()
        }
    }
    
    if (Test-Path $soulPath) {
        $soul = Get-Content $soulPath -Raw -ErrorAction SilentlyContinue
        if ($soul -match "^#\s+(.+?)(?:\n|\r)") {
            $id.ArchitectName = $Matches[1].Trim()
        }
    }
    
    return $id
}

# =============================================================================
# STATE MANAGEMENT
# =============================================================================

function Set-ButtonState {
    param(
        [string]$State,
        [string]$Title = "",
        [string]$Message = $null
    )
    
    $script:CurrentState = $State
    
    $titles = @{
        idle = ""
        active = "*"
        processing = "..."
        complete = "OK"
        error = "ERR"
        demo = "DEMO"
    }
    
    $displayTitle = if ($Title) { $Title } else { $titles[$State] }
    
    $output = @{
        event = "setState"
        context = $script:ContextId
        payload = @{
            state = if ($State -eq "error") { "1" } else { "0" }
            title = $displayTitle
        }
    } | ConvertTo-Json -Compress
    
    Write-Host $output
    
    if ($Message) {
        Write-Host "Feedback: $Message"
    }
}

# =============================================================================
# HTTP API
# =============================================================================

function Invoke-OpenClawAPI {
    param(
        [string]$Endpoint,
        [string]$Method = "GET",
        [hashtable]$Body = @{},
        [int]$TimeoutSec = $script:TimeoutSec
    )
    
    $url = $script:GatewayURL + $Endpoint
    
    try {
        if ($Method -eq "GET") {
            $response = Invoke-RestMethod -Uri $url -Method GET -TimeoutSec $TimeoutSec
            return @{ Success = $true; Data = $response }
        } else {
            $json = $Body | ConvertTo-Json -Depth 5
            $response = Invoke-RestMethod -Uri $url -Method POST -Body $json -ContentType "application/json" -TimeoutSec $TimeoutSec
            return @{ Success = $true; Data = $response }
        }
    } catch {
        return @{ Success = $false; Error = $_.Exception.Message }
    }
}

# =============================================================================
# RECONNECTION
# =============================================================================

function Test-GatewayConnection {
    $result = Invoke-OpenClawAPI -Endpoint "/status" -TimeoutSec 3
    return $result.Success
}

function Invoke-Reconnect {
    $attempt = 0
    $delay = $script:ReconnectDelay
    
    while ($attempt -lt $script:ReconnectAttempts) {
        $attempt++
        Set-ButtonState -State "processing" -Title "↻ $attempt" -Message "Reconnecting..."
        
        if (Test-GatewayConnection) {
            Set-ButtonState -State "idle" -Title "" -Message "Connected!"
            return $true
        }
        
        Start-Sleep -Seconds $delay
        $delay = [math]::Min($delay * 2, 30)
    }
    
    Set-ButtonState -State "error" -Title "✗" -Message "Connection failed"
    return $false
}

# =============================================================================
# DEMO MODE
# =============================================================================

function Invoke-DemoAction {
    param([string]$ActionName)
    
    Set-ButtonState -State "demo" -Title "DEMO"
    Write-Host "Demo mode - no OpenClaw connection needed"
    
    # Simulate thinking steps
    $script:DemoSteps | ForEach-Object {
        Set-ButtonState -State "processing" -Title $_.Text
        Start-Sleep -Milliseconds $_.Duration
    }
    
    Set-ButtonState -State "complete" -Title "Done!"
    Start-Sleep -Milliseconds $script:StateCooldownMs
    Set-ButtonState -State "idle" -Title ""
}

# =============================================================================
# ACTIONS
# =============================================================================

function Invoke-SpawnAction {
    if ($script:DemoMode) {
        Invoke-DemoAction -ActionName "spawn"
        return
    }
    
    Set-ButtonState -State "active" -Title "Spawning..."
    
    $result = Invoke-OpenClawAPI -Endpoint "/spawn" -Method "POST" -Body @{ 
        task = "Quick assistance"
        agentId = "helper"
    }
    
    if ($result.Success) {
        # Show thinking animation
        Set-ButtonState -State "processing" -Title "Spawning..."
        Start-Sleep -Milliseconds 800
        Set-ButtonState -State "processing" -Title "Starting..."
        Start-Sleep -Milliseconds 600
        Set-ButtonState -State "processing" -Title "Running..."
        Start-Sleep -Milliseconds 1500
        Set-ButtonState -State "complete" -Title "OK"
    } else {
        Set-ButtonState -State "error" -Title "ERR"
    }
    
    Start-Sleep -Milliseconds $script:StateCooldownMs
    Set-ButtonState -State "idle"
}

function Invoke-TTSAction {
    if ($script:DemoMode) {
        Invoke-DemoAction -ActionName "tts"
        return
    }
    
    Set-ButtonState -State "active" -Title "TTS..."
    $result = Invoke-OpenClawAPI -Endpoint "/config.get" -Method "GET"
    
    if ($result.Success) {
        $current = $result.Data.messages.tts.enabled
        $newState = -not $current
        Invoke-OpenClawAPI -Endpoint "/config.patch" -Method "POST" -Body @{ path = "messages.tts.enabled"; value = $newState }
        Set-ButtonState -State "complete" -Title "TTS:$(if($newState){'ON'}else{'OFF'})"
    } else {
        Set-ButtonState -State "error" -Title "ERR"
    }
    
    Start-Sleep -Milliseconds $script:StateCooldownMs
    Set-ButtonState -State "idle"
}

function Invoke-StatusAction {
    Set-ButtonState -State "active" -Title "Checking..."
    
    if ($script:DemoMode) {
        Start-Sleep -Milliseconds 500
        Set-ButtonState -State "complete" -Title "Demo OK"
        Start-Sleep -Milliseconds 1000
        Set-ButtonState -State "idle"
        return
    }
    
    $result = Invoke-OpenClawAPI -Endpoint "/status"
    if ($result.Success) {
        $latency = if ($result.Data.latencyMs) { $result.Data.latencyMs } else { "?" }
        Set-ButtonState -State "complete" -Title "${latency}ms"
    } else {
        Set-ButtonState -State "error" -Title "Offline"
        Invoke-Reconnect
    }
    
    Start-Sleep -Milliseconds 2000
    Set-ButtonState -State "idle"
}

function Invoke-IdentityAction {
    $id = Get-AgentIdentity
    Set-ButtonState -State "active" -Title $id.Emoji
    Start-Sleep -Milliseconds 1500
    $shortName = $id.Name.Substring(0, [Math]::Min(4, $id.Name.Length))
    Set-ButtonState -State "idle" -Title $shortName
    Start-Sleep -Milliseconds 3000
    Set-ButtonState -State "idle" -Title ""
}

function Invoke-WebSearchAction {
    if ($script:DemoMode) {
        Invoke-DemoAction -ActionName "websearch"
        return
    }
    
    Set-ButtonState -State "active" -Title "Search..."
    Start-Sleep -Milliseconds 1000
    Set-ButtonState -State "processing" -Title "Fetching..."
    Start-Sleep -Milliseconds 800
    Set-ButtonState -State "processing" -Title "Parsing..."
    Start-Sleep -Milliseconds 600
    
    $result = Invoke-OpenClawAPI -Endpoint "/web.search" -Method "POST" -Body @{ query = "Latest tech" }
    
    if ($result.Success) {
        Set-ButtonState -State "complete" -Title "Found!"
    } else {
        Set-ButtonState -State "error" -Title "✗"
    }
    
    Start-Sleep -Milliseconds $script:StateCooldownMs
    Set-ButtonState -State "idle"
}

function Invoke-SubagentsAction {
    if ($script:DemoMode) { 
        Set-ButtonState -State "complete" -Title "3 active"
        Start-Sleep -Milliseconds 2000
        Set-ButtonState -State "idle"
        return 
    }
    
    Set-ButtonState -State "active" -Title "Loading..."
    $result = Invoke-OpenClawAPI -Endpoint "/subagents.list"
    
    if ($result.Success) {
        $count = $result.Data.agents.Count
        Set-ButtonState -State "complete" -Title "$count active"
    } else {
        Set-ButtonState -State "error" -Title "✗"
    }
    
    Start-Sleep -Milliseconds 3000
    Set-ButtonState -State "idle"
}

function Invoke-NodesAction {
    if ($script:DemoMode) { 
        Set-ButtonState -State "complete" -Title "2 nodes"
        Start-Sleep -Milliseconds 2000
        Set-ButtonState -State "idle"
        return 
    }
    
    Set-ButtonState -State "active" -Title "Scanning..."
    Start-Sleep -Milliseconds 800
    Set-ButtonState -State "processing" -Title "Pinging..."
    Start-Sleep -Milliseconds 600
    
    $result = Invoke-OpenClawAPI -Endpoint "/nodes.status"
    
    if ($result.Success) {
        $count = $result.Data.nodes.Count
        Set-ButtonState -State "complete" -Title "$count nodes"
    } else {
        Set-ButtonState -State "error" -Title "✗"
    }
    
    Start-Sleep -Milliseconds 3000
    Set-ButtonState -State "idle"
}

function Invoke-SessionAction {
    if ($script:DemoMode) { 
        Set-ButtonState -State "complete" -Title "Demo Session"
        Start-Sleep -Milliseconds 2000
        Set-ButtonState -State "idle"
        return 
    }
    
    Set-ButtonState -State "active" -Title "Session..."
    $result = Invoke-OpenClawAPI -Endpoint "/session.status"
    
    if ($result.Success) {
        $model = ($result.Data.model -split "/")[-1]
        $shortModel = $model.Substring(0, [Math]::Min(6, $model.Length))
        Set-ButtonState -State "complete" -Title $shortModel
    } else {
        Set-ButtonState -State "error" -Title "✗"
    }
    
    Start-Sleep -Milliseconds 3000
    Set-ButtonState -State "idle"
}

function Invoke-ReconnectAction {
    Set-ButtonState -State "active" -Title "Reconnect"
    $success = Invoke-Reconnect
    if (-not $success) {
        Start-Sleep -Milliseconds 2000
    }
    Set-ButtonState -State "idle"
}

function Invoke-DemoToggleAction {
    $script:DemoMode = -not $script:DemoMode
    Set-ButtonState -State "demo" -Title $(if($script:DemoMode){"DEMO:ON"}else{"DEMO:OFF"})
    Start-Sleep -Milliseconds 1500
    Set-ButtonState -State "idle"
}

# =============================================================================
# MAIN
# =============================================================================

# Parse settings
$parsedSettings = $Settings | ConvertFrom-Json -ErrorAction SilentlyContinue

if ($parsedSettings.gateway) { $script:GatewayURL = $parsedSettings.gateway }
if ($parsedSettings.demoMode) { $script:DemoMode = [bool]$parsedSettings.demoMode }
if ($parsedSettings.context) { $script:ContextId = $parsedSettings.context }

# Route action
switch ($Action) {
    "spawn" { Invoke-SpawnAction }
    "tts" { Invoke-TTSAction }
    "status" { Invoke-StatusAction }
    "identity" { Invoke-IdentityAction }
    "websearch" { Invoke-WebSearchAction }
    "subagents" { Invoke-SubagentsAction }
    "nodes" { Invoke-NodesAction }
    "session" { Invoke-SessionAction }
    "reconnect" { Invoke-ReconnectAction }
    "demo-toggle" { Invoke-DemoToggleAction }
    default {
        Write-Error "Unknown action: $Action"
        exit 1
    }
}

exit 0
