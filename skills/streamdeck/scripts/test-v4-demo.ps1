# Test OpenClaw Live v4 in Demo Mode
# No OpenClaw connection required - simulates all features

param(
    [string]$Action = "status",
    [switch]$ListActions
)

$pluginPath = "$env:USERPROFILE\.openclaw\workspace\skills\streamdeck\plugin-v4\openclaw-live-activity.ps1"

if ($ListActions) {
    Write-Host "Available Actions:" -ForegroundColor Cyan
    @("tts", "spawn", "status", "identity", "demo-toggle", "websearch", "reconnect", "subagents", "nodes", "session") | ForEach-Object {
        Write-Host "  - $_" -ForegroundColor Gray
    }
    return
}

$settings = @{ demoMode = $true; gateway = "http://demo.local:18790" } | ConvertTo-Json -Compress

Write-Host "Testing OpenClaw Live v4 (Demo Mode)" -ForegroundColor Cyan
Write-Host "Action: $Action" -ForegroundColor Gray
Write-Host "Settings: $settings`n" -ForegroundColor Gray

& $pluginPath -Action $Action -Settings $settings -Context "test-context"

Write-Host "`nDemo complete!`n" -ForegroundColor Green
Write-Host "Test other actions:" -ForegroundColor Cyan
Write-Host "  .\test-v4-demo.ps1 -Action spawn" -ForegroundColor White
Write-Host "  .\test-v4-demo.ps1 -Action websearch" -ForegroundColor White
Write-Host "  .\test-v4-demo.ps1 -Action identity" -ForegroundColor White
Write-Host "  .\test-v4-demo.ps1 -ListActions" -ForegroundColor White
