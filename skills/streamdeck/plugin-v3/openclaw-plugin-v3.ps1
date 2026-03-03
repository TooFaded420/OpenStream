# OpenClaw Stream Deck Plugin v3.0
# Features: Multi-Gateway, Dynamic Status, Custom Actions

param(
    [Parameter(Mandatory=$true)]
    [string]$Action,
    
    [string]$Settings = "{}",
    [string]$Event = "keyUp"
)

$ErrorActionPreference = "Stop"

# Default gateways (can be configured)
$Global:Gateways = @{
    "primary" = "http://127.0.0.1:18790"
    "secondary" = $null
    "work" = $null
    "home" = $null
}

# Pre-built button configurations
$PrebuiltActions = @{
    # Core actions
    "tts" = @{ Name = "TTS Toggle"; Endpoint = "/tts.toggle"; Method = "POST"; Icon = "tts.png" }
    "spawn" = @{ Name = "Spawn Agent"; Endpoint = "/spawn"; Method = "POST"; Icon = "spawn.png"; Body = @{ task = "Quick task" } }
    "status" = @{ Name = "Status Check"; Endpoint = "/status"; Method = "GET"; Icon = "status.png" }
    
    # Model actions
    "models" = @{ Name = "List Models"; Endpoint = "/models"; Method = "GET"; Icon = "models.png" }
    "modelswitch" = @{ Name = "Switch Model"; Endpoint = "/config.patch"; Method = "POST"; Icon = "models.png"; Body = @{ model = "synthetic/hf:moonshotai/Kimi-K2.5" } }
    
    # Subagent actions
    "subagents" = @{ Name = "Subagents"; Endpoint = "/subagents.list"; Method = "GET"; Icon = "subagents.png" }
    "subagent-kill" = @{ Name = "Kill All"; Endpoint = "/subagents.kill"; Method = "POST"; Icon = "subagents.png"; Body = @{ target = "all" } }
    
    # System actions
    "nodes" = @{ Name = "Node Status"; Endpoint = "/nodes.status"; Method = "GET"; Icon = "nodes.png" }
    "restart" = @{ Name = "Restart Gateway"; Endpoint = "/gateway.restart"; Method = "POST"; Icon = "restart.png" }
    "config" = @{ Name = "View Config"; Endpoint = "/config.get"; Method = "GET"; Icon = "config.png" }
    "session" = @{ Name = "Session Status"; Endpoint = "/session.status"; Method = "GET"; Icon = "session.png" }
    
    # Tool actions
    "websearch" = @{ Name = "Web Search"; Endpoint = "/web.search"; Method = "POST"; Icon = "websearch.png"; Body = @{ query = "Latest tech news" } }
    "memory" = @{ Name = "Memory Search"; Endpoint = "/memory_search"; Method = "POST"; Icon = "memory.png"; Body = @{ query = "recent projects" } }
    
    # Coding actions
    "coding-spawn" = @{ Name = "Code Agent"; Endpoint = "/spawn"; Method = "POST"; Icon = "coding.png"; Body = @{ task = "Review code and suggest improvements"; agentId = "coding" } }
    "coding-debug" = @{ Name = "Debug Help"; Endpoint = "/spawn"; Method = "POST"; Icon = "coding.png"; Body = @{ task = "Debug this error"; agentId = "debug" } }
    
    # Messaging actions
    "message-send" = @{ Name = "Send Message"; Endpoint = "/message.send"; Method = "POST"; Icon = "message.png"; Body = @{ text = "Hello from Stream Deck!"; channel = "telegram" } }
    "message-broadcast" = @{ Name = "Broadcast"; Endpoint = "/message.send"; Method = "POST"; Icon = "message.png"; Body = @{ text = "Update: Task complete"; channel = "all" } }
    
    # Quick actions
    "quick-yes" = @{ Name = "✓ Yes"; Endpoint = "/message.send"; Method = "POST"; Icon = "status.png"; Body = @{ text = "Yes, approved"; channel = "telegram" } }
    "quick-no" = @{ Name = "✗ No"; Endpoint = "/message.send"; Method = "POST"; Icon = "restart.png"; Body = @{ text = "No, rejected"; channel = "telegram" } }
    
    # Status monitoring
    "gateway-status" = @{ Name = "Gateway Check"; Endpoint = "/gateway.status"; Method = "GET"; Icon = "status.png" }
    "system-health" = @{ Name = "Health Check"; Endpoint = "/health"; Method = "GET"; Icon = "status.png" }
    
    # Advanced actions
    "cron-list" = @{ Name = "Cron Jobs"; Endpoint = "/cron.list"; Method = "GET"; Icon = "config.png" }
    "cron-run" = @{ Name = "Run Cron"; Endpoint = "/cron.run"; Method = "POST"; Icon = "config.png"; Body = @{ jobId = "daily-check" } }
}

# Custom actions storage
$Global:CustomActions = @{}

function Send-ToOpenClaw {
    param(
        [string]$GatewayKey = "primary",
        [string]$Endpoint,
        [string]$Method = "POST",
        [hashtable]$Body = @{},
        [int]$TimeoutSec = 5
    )
    
    $baseUrl = $Global:Gateways[$GatewayKey]
    
    # Validate URL
    if (-not $baseUrl) {
        return @{ Success = $false; Error = "Gateway '$GatewayKey' not configured. Check settings." }
    }
    
    if (-not $baseUrl -match "^https?://") {
        $baseUrl = "http://$baseUrl"
    }
    
    $url = $baseUrl + $Endpoint
    
    try {
        if ($Method -eq "GET") {
            $response = Invoke-RestMethod -Uri $url -Method Get -TimeoutSec $TimeoutSec
        } else {
            $jsonBody = $Body | ConvertTo-Json -Depth 3
            $response = Invoke-RestMethod -Uri $url -Method Post -Body $jsonBody -ContentType "application/json" -TimeoutSec $TimeoutSec
        }
        
        return @{ Success = $true; Data = $response; Gateway = $GatewayKey }
    } catch {
        # Better error messages
        $errorMsg = switch -Regex ($_.Exception.Message) {
            "connection.*refused" { "OpenClaw gateway offline. Make sure it's running on $GatewayKey." }
            "timeout" { "Network timeout. Check your connection to $GatewayKey." }
            "name.*resolution" { "Can't find gateway. Check the IP address in settings." }
            "401|403" { "Authentication failed. Check your device token." }
            default { "Connection error: $($_.Exception.Message.Split(':')[0])" }
        }
        
        # Try fallback gateway if primary failed
        if ($GatewayKey -eq "primary" -and $Global:Gateways["secondary"]) {
            Write-Host "Primary failed, trying secondary..."
            return Send-ToOpenClaw -GatewayKey "secondary" -Endpoint $Endpoint -Method $Method -Body $Body -TimeoutSec $TimeoutSec
        }
        
        return @{ Success = $false; Error = $errorMsg; Gateway = $GatewayKey }
    }
}

function Update-KeyState {
    param([string]$State, [string]$Message)
    
    $output = @{
        event = "setState"
        context = $env:STREAMDECK_CONTEXT
        payload = @{
            state = $State
            title = $Message
        }
    } | ConvertTo-Json -Compress
    
    Write-Host $output
}

function Test-GatewayStatus {
    param([string]$GatewayKey = "primary")
    
    $url = $Global:Gateways[$GatewayKey]
    if (-not $url) { return @{ Online = $false; Reason = "Not configured" } }
    
    try {
        $response = Invoke-RestMethod -Uri "$url/status" -Method Get -TimeoutSec 2
        return @{ Online = $true; Version = $response.version }
    } catch {
        return @{ Online = $false; Reason = $_.Exception.Message }
    }
}

# Parse settings
$parsedSettings = $Settings | ConvertFrom-Json -ErrorAction SilentlyContinue

# Update gateways from settings
if ($parsedSettings.gateways) {
    foreach ($g in $parsedSettings.gateways.PSObject.Properties) {
        $Global:Gateways[$g.Name] = $g.Value
    }
}

# Update custom actions
if ($parsedSettings.customActions) {
    foreach ($action in $parsedSettings.customActions) {
        $Global:CustomActions[$action.id] = $action
    }
}

# Determine which gateway to use
$gatewayKey = $parsedSettings.gatewayKey ?? "primary"

# Execute action
$result = $null

# Check if it's a pre-built action
if ($PrebuiltActions[$Action]) {
    $actionConfig = $PrebuiltActions[$Action]
    $body = $actionConfig.Body ?? @{}
    
    # Override with custom settings if provided
    if ($parsedSettings.customBody) {
        $body = $parsedSettings.customBody
    }
    
    $result = Send-ToOpenClaw -GatewayKey $gatewayKey -Endpoint $actionConfig.Endpoint -Method $actionConfig.Method -Body $body
}
# Check if it's a custom action
elseif ($Global:CustomActions[$Action]) {
    $custom = $Global:CustomActions[$Action]
    $result = Send-ToOpenClaw -GatewayKey $gatewayKey -Endpoint $custom.endpoint -Method $custom.method -Body $custom.body
}
# Special actions
elseif ($Action -eq "status-dynamic") {
    # Dynamic status check
    $status = Test-GatewayStatus -GatewayKey $gatewayKey
    if ($status.Online) {
        Update-KeyState -State "0" -Message "✓"
        $result = @{ Success = $true; Data = $status }
    } else {
        Update-KeyState -State "1" -Message "✗"
        $result = @{ Success = $false; Error = $status.Reason }
    }
}
elseif ($Action -eq "gateway-switch") {
    # Switch to next available gateway
    $current = $gatewayKey
    $next = if ($current -eq "primary") { "secondary" } else { "primary" }
    
    $test = Test-GatewayStatus -GatewayKey $next
    if ($test.Online) {
        Update-KeyState -State "0" -Message "G:$next"
        $result = @{ Success = $true; Data = @{ SwitchedTo = $next } }
    } else {
        Update-KeyState -State "1" -Message "No GW"
        $result = @{ Success = $false; Error = "No gateway available" }
    }
}
else {
    $result = @{ Success = $false; Error = "Unknown action: $Action" }
}

# Output result
if ($result.Success) {
    Write-Host "✓ $Action completed"
    exit 0
} else {
    Write-Error "✗ $Action failed: $($result.Error)"
    exit 1
}
