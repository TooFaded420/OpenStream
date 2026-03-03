# Core Detection Module
# Detects hardware, software, and environment

function Get-StreamDeckHardware {
    [CmdletBinding()]
    param()
    
    $devices = @()
    $regPath = "HKLM:\SYSTEM\CurrentControlSet\Enum\USB\VID_0FD9*"
    
    if (Test-Path $regPath) {
        Get-ChildItem $regPath -ErrorAction SilentlyContinue | ForEach-Object {
            $devices += [PSCustomObject]@{
                Name = $_.PSChildName
                Type = switch -Regex ($_.Name) {
                    "0063" { "MK.2" }
                    "0080" { "XL" }
                    "0084" { "Plus" }
                    default { "Unknown" }
                }
                Path = $_.PSPath
            }
        }
    }
    
    return $devices
}

function Get-StreamDeckSoftware {
    [CmdletBinding()]
    param()
    
    $paths = @(
        "$env:ProgramFiles\Elgato\StreamDeck\StreamDeck.exe",
        "$env:LOCALAPPDATA\Programs\Elgato\StreamDeck\StreamDeck.exe"
    )
    
    foreach ($path in $paths) {
        if (Test-Path $path) {
            return [PSCustomObject]@{
                Installed = $true
                Path = $path
                Running = (Get-Process "StreamDeck" -ErrorAction SilentlyContinue) -ne $null
                Version = (Get-Item $path).VersionInfo.FileVersion
            }
        }
    }
    
    return [PSCustomObject]@{ Installed = $false }
}

function Get-OpenClawStatus {
    [CmdletBinding()]
    param()
    
    $status = [PSCustomObject]@{
        Installed = $false
        GatewayRunning = $false
        Port = 18790
        Version = $null
    }
    
    try {
        $oc = Get-Command "openclaw" -ErrorAction SilentlyContinue
        if ($oc) {
            $status.Installed = $true
            # Could parse version here
        }
        
        $response = Invoke-RestMethod -Uri "http://127.0.0.1:18790/status" -Method Get -TimeoutSec 2
        $status.GatewayRunning = $true
        $status.Port = 18790
    } catch {}
    
    return $status
}

Export-ModuleMember -Function Get-StreamDeckHardware, Get-StreamDeckSoftware, Get-OpenCl