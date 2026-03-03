# Service Module
# Usage: .\Module-Service.ps1 -Action "Start|Stop|Status"
# Manages background service

param([string]$Action = "Status")

$ServiceName = "OpenClawStreamDeck"

switch ($Action) {
    "Start" {
        $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 5)
        $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-File `"$PSScriptRoot\Service-Worker.ps1`""
        Register-ScheduledTask -TaskName $ServiceName -Trigger $trigger -Action $action -Force
        return "Service started"
    }
    "Stop" {
        Unregister-ScheduledTask -TaskName $ServiceName -Confirm:$false
        return "Service stopped"
    }
    "Status" {
        $task = Get-ScheduledTask -TaskName $ServiceName -ErrorAction SilentlyContinue
        return @{ Running = $task -ne $null; LastRun = $task.LastRunTime }
    }
}