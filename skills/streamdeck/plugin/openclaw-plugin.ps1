# OpenClaw Stream Deck Plugin v2.0
# Premium features: status display, multi-gateway, animations

param(
    [Parameter(Mandatory=$true)]
    [string]$Action,
    
    [string]$GatewayUrl = "http://127.0.0.1:18790",
    [string]$Settings = "{}",
    [string]$Event = "keyUp"
)

$ErrorActionPreference = "Stop"
$LogFile = "$env:TEMP\openclaw-plugin.log"

function Write-Log {
    param([string]$Message)
    "$(Get-Date -Format 'HH:mm:ss') $Message" | Out-File $LogFile -Append
}

function Send-ToOpenClaw {
    param([string]$Endpoint, [hashtable]$Body = @{}, [string]$Method = "POST")
    
    try {
        $uri = "$GatewayUrl/$Endpoint"
        $jsonBody = $Body | ConvertTo-Json -Depth 5
        
        if ($Method -eq "GET") {
            $response = Invoke-RestMethod -Uri $uri -Method Get -TimeoutSec 5
        } else {
            $response = Invoke-RestMethod -Uri $uri -Method Post -Body $jsonBody -ContentType "application/json" -TimeoutSec 5
        }
        
        return @{ Success = $true; Data = $response }
    } catch {
        Write-Log "Error: $($_.Exception.Message)"
        return @{ Success = $false; Error = $_.Exception.Message }
    }
}

function Update-KeyState {
    param([string]$State, [string]$Message)
    
    # Output JSON that Stream Deck can read
    $output = @{
        event = "setState"
        context = $env:STREAMDECK_CONTEXT
        payload = @{
            state = $State
            message = $Message
        }
    } | ConvertTo-Json -Compress
    
    Write-Host $output
}

# Main execution
Write-Log "Action: $Action, Event: $Event"

# Parse settings
$parsedSettings = $Settings | ConvertFrom-Json -ErrorAction SilentlyContinue
if ($parsedSettings.gatewayUrl) {
    $GatewayUrl = $parsedSettings.gatewayUrl
}

# Execute action
$result = switch ($Action) {
    "tts" { 
        Send-ToOpenClaw -Endpoint "tts.toggle" 
    }
    "spawn" { 
        $task = $parsedSettings.customTask ?? "Quick task from Stream Deck"
        Send-ToOpenClaw -Endpoint "spawn" -Body @{ 
            task = $task
            agentId = $parsedSettings.agentId ?? "main"
        }
    }
    "status" { 
        $res = Send-ToOpenClaw -Endpoint "status" -Method "GET"
        if ($res.Success) {
            Update-KeyState -State "0" -Message "Online"
        }
        $res
    }
    "models" { 
        Send-ToOpenClaw -Endpoint "models" 
    }
    "subagents" { 
        Send-ToOpenClaw -Endpoint "subagents" 
    }
    "nodes" { 
        Send-ToOpenClaw -Endpoint "nodes.status" 
    }
    "restart" { 
        Send-ToOpenClaw -Endpoint "gateway.restart" 
    }
    "config" { 
        Send-ToOpenClaw -Endpoint "config.get" 
    }
    "session" { 
        Send-ToOpenClaw -Endpoint "session.status" 
    }
    "websearch" { 
        $query = $parsedSettings.searchQuery ?? "Stream Deck"
        Send-ToOpenClaw -Endpoint "web.search" -Body @{ query = $query }
    }
    "memory" {
        $search = $parsedSettings.memoryQuery ?? "recent"
        Send-ToOpenClaw -Endpoint "memory.search" -Body @{ query = $search }
    }
    "coding" {
        $task = $parsedSettings.codingTask ?? "Analyze code"
        Send-ToOpenClaw -Endpoint "spawn" -Body @{ 
            task = "Code: $task"
            agentId = "coding"
        }
    }
    "message" {
        $msg = $parsedSettings.messageText ?? "Hello from Stream Deck"
        Send-ToOpenClaw -Endpoint "message.send" -Body @{ 
            text = $msg
            channel = $parsedSettings.channel ?? "telegram"
        }
    }
    default {
        @{ Success = $false; Error = "Unknown action: $Action" }
    }
}

# Return result
if ($result.Success) {
    Write-Host "✓ $Action completed"
    Update-KeyState -State "0" -Message "OK"
    exit 0
} else {
    Write-Error "✗ $Action failed: $($result.Error)"
    Update-KeyState -State "1" -Message "Error"
    exit 1
}
