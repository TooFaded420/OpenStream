# Add Mission to Queue - Stream Deck Action
param(
    [Parameter(Mandatory=$true)][string]$Title,
    [string]$Description = "",
    [ValidateSet("low","normal","high")][string]$Priority = "normal",
    [string]$DashboardUrl = "http://127.0.0.1:8787"
)

$ErrorActionPreference = 'Stop'

function Send-Notification([string]$title, [string]$message, [string]$type = "info") {
    try {
        Add-Type -AssemblyName System.Windows.Forms -ErrorAction SilentlyContinue
        $icon = if ($type -eq "error") { [System.Windows.Forms.MessageBoxIcon]::Error } else { [System.Windows.Forms.MessageBoxIcon]::Information }
        [System.Windows.Forms.MessageBox]::Show($message, $title, "OK", $icon) | Out-Null
    } catch {
        Write-Host "$title`: $message" -ForegroundColor $(if ($type -eq "error") { "Red" } else { "Green" })
    }
}

try {
    $body = @{
        title = $Title
        description = $Description
        priority = $Priority
        source = "streamdeck"
    } | ConvertTo-Json

    $headers = @{ "Content-Type" = "application/json" }
    $response = Invoke-RestMethod -Uri "$DashboardUrl/api/missions" -Method Post -Headers $headers -Body $body -TimeoutSec 5

    if ($response.ok) {
        $missionId = $response.mission.id
        Send-Notification "Mission Added" "Mission #$missionId added to queue: $Title" "info"
        exit 0
    } else {
        throw "API returned error"
    }
} catch {
    Send-Notification "Mission Failed" "Failed to add mission: $($_.Exception.Message)" "error"
    exit 1
}
