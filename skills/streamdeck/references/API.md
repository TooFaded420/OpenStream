# OpenClaw API Reference for Stream Deck

Complete API documentation for OpenClaw webhook integration.

## Base URL

```
http://127.0.0.1:18790
```

Change in `plugin/webhooks.ps1` if using different port.

## Authentication

If authentication enabled:

```powershell
$Headers = @{
    "Authorization" = "Bearer YOUR_TOKEN"
}
```

## Endpoints

### TTS

**Generate speech from text.**

```http
POST /tts
Content-Type: application/json

{
  "text": "Hello from Stream Deck",
  "voice": "default",
  "speed": 1.0
}
```

**Response:**
```json
{
  "success": true,
  "audio_url": "/audio/tts-12345.mp3"
}
```

### Spawn Agent

**Spawn a sub-agent for task execution.**

```http
POST /spawn
Content-Type: application/json

{
  "task": "Analyze this code and suggest improvements",
  "agentId": "main",
  "timeout": 300,
  "thinking": "on"
}
```

**Response:**
```json
{
  "success": true,
  "session_key": "agent:main:subagent:abc123",
  "status": "running"
}
```

### Status

**Get OpenClaw system status.**

```http
GET /status
```

**Response:**
```json
{
  "gateway": "running",
  "port": 18790,
  "sessions": 3,
  "models": ["synthetic/hf:MiniMaxAI/MiniMax-M2.1"],
  "nodes": 1,
  "uptime": "2h 15m"
}
```

### Sessions List

**List active sessions.**

```http
GET /sessions
```

**Response:**
```json
{
  "sessions": [
    {
      "key": "agent:main:main",
      "agent": "main",
      "status": "active",
      "started_at": "2026-02-21T10:00:00Z"
    }
  ]
}
```

### Session History

**Get session message history.**

```http
GET /sessions/{session_key}/history?limit=50
```

**Response:**
```json
{
  "messages": [
    {
      "role": "user",
      "content": "Hello",
      "timestamp": "2026-02-21T10:00:00Z"
    }
  ]
}
```

### Send Message

**Send message to a session.**

```http
POST /message
Content-Type: application/json

{
  "session_key": "agent:main:main",
  "message": "Hello from Stream Deck button",
  "deliver": true
}
```

### Models

**List available models.**

```http
GET /models
```

**Response:**
```json
{
  "models": [
    {
      "id": "synthetic/hf:MiniMaxAI/MiniMax-M2.1",
      "name": "MiniMax M2.1",
      "provider": "synthetic"
    }
  ]
}
```

### Nodes

**List paired nodes.**

```http
GET /nodes
```

**Response:**
```json
{
  "nodes": [
    {
      "id": "mac-mini",
      "name": "Mac Mini",
      "status": "connected",
      "last_seen": "2026-02-21T10:00:00Z"
    }
  ]
}
```

### Subagents

**List active subagents.**

```http
GET /subagents
```

**Response:**
```json
{
  "subagents": [
    {
      "key": "agent:main:subagent:abc123",
      "label": "daily-journal-architect",
      "status": "running",
      "started": "2026-02-21T10:00:00Z"
    }
  ]
}
```

### Gateway Restart

**Restart the gateway.**

```http
POST /gateway/restart
```

**Response:**
```json
{
  "success": true,
  "message": "Gateway restarted",
  "pid": 12345
}
```

### Config Get

**Get configuration value.**

```http
GET /config/{path}
```

Example:
```http
GET /config/gateway.port
```

**Response:**
```json
{
  "path": "gateway.port",
  "value": 18790
}
```

### Web Search

**Perform web search.**

```http
POST /search
Content-Type: application/json

{
  "query": "OpenClaw documentation",
  "count": 5,
  "provider": "brave"
}
```

### Memory Search

**Search memory files.**

```http
POST /memory/search
Content-Type: application/json

{
  "query": "Stream Deck project",
  "max_results": 10
}
```

## Error Responses

All endpoints return consistent error format:

```json
{
  "error": true,
  "code": "GATEWAY_TIMEOUT",
  "message": "Gateway did not respond within timeout",
  "status": 504
}
```

Common error codes:
- `UNAUTHORIZED` — Invalid or missing token
- `GATEWAY_TIMEOUT` — Gateway not responding
- `SESSION_NOT_FOUND` — Session key invalid
- `MODEL_NOT_FOUND` — Model ID invalid
- `RATE_LIMITED` — Too many requests

## Rate Limits

Default limits:
- **TTS:** 10 requests/minute
- **Spawn:** 5 agents/minute
- **Status:** 60 requests/minute
- **Other:** 120 requests/minute

## PowerShell Examples

### Invoke-TTS

```powershell
function Invoke-TTS {
    param([string]$Text)
    
    $Uri = "http://127.0.0.1:18790/tts"
    $Body = @{ text = $Text } | ConvertTo-Json
    
    Invoke-RestMethod -Uri $Uri -Method Post -Body $Body -ContentType "application/json"
}

Invoke-TTS "Hello from Stream Deck"
```

### Get-OpenClawStatus

```powershell
function Get-OpenClawStatus {
    $Uri = "http://127.0.0.1:18790/status"
    Invoke-RestMethod -Uri $Uri -Method Get
}

$status = Get-OpenClawStatus
Write-Host "Gateway: $($status.gateway)"
Write-Host "Sessions: $($status.sessions)"
```

### Spawn-Agent

```powershell
function Spawn-Agent {
    param([string]$Task)
    
    $Uri = "http://127.0.0.1:18790/spawn"
    $Body = @{
        task = $Task
        agentId = "main"
    } | ConvertTo-Json
    
    Invoke-RestMethod -Uri $Uri -Method Post -Body $Body -ContentType "application/json"
}

Spawn-Agent "Analyze this code"
```

## Testing

Test endpoints manually:

```powershell
# Status
Invoke-RestMethod -Uri "http://127.0.0.1:18790/status"

# Models
Invoke-RestMethod -Uri "http://127.0.0.1:18790/models"

# TTS
Invoke-RestMethod -Uri "http://127.0.0.1:18790/tts" -Method Post -Body '{"text":"test"}' -ContentType "application/json"
```