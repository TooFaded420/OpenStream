# Stream Deck Detection Script
# Detects all connected Stream Deck devices and their configurations

$script:Version = "1.0.0"
$script:LogFile = "$env:TEMP\streamdeck-detect.log"

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp [$Level] $Message" | Tee-Object -FilePath $LogFile -Append | Write-Host
}

function Get-StreamDeckDevices {
    Write-Log "Detecting Stream Deck devices..."
    
    $devices = @()
    
    # Check for Stream Deck via USB (using WMI)
    $usbDevices = Get-PnpDevice -Class USB | Where-Object { 
        $_.FriendlyName -like "*Stream Deck*" -or 
        $_.InstanceId -like "*4057*" -or  # Elgato vendor ID
        $_.InstanceId -like "*0FD9*"      # Alternative vendor ID
    }
    
    foreach ($usb in $usbDevices) {
        Write-Log "Found USB device: $($usb.FriendlyName)"
    }
    
    # Check registry for installed Stream Decks
    $regPath = "HKLM:\SYSTEM\CurrentControlSet\Enum\USB"
    if (Test-Path $regPath) {
        $streamDeckKeys = Get-ChildItem $regPath -Recurse -ErrorAction SilentlyContinue | 
            Where-Object { $_.Name -like "*4057*" -or $_.Name -like "*0FD9*" }
        
        foreach ($key in $streamDeckKeys) {
            Write-Log "Found registry entry: $($key.Name)"
        }
    }
    
    # Check Stream Deck software profiles
    $sdAppData = "$env:APPDATA\Elgato\StreamDeck\ProfilesV2"
    if (Test-Path $sdAppData) {
        $profiles = Get-ChildItem $sdAppData -Directory
        Write-Log "Found $($profiles.Count) Stream Deck profile(s)"
        
        foreach ($profile in $profiles) {
            $manifestPath = "$($profile.FullName)\manifest.json"
            if (Test-Path $manifestPath) {
                $manifest = Get-Content $manifestPath | ConvertFrom-Json
                
                $deviceInfo = @{
                    ProfileID = $profile.Name
                    DeviceModel = $manifest.Device.Model
                    DeviceUUID = $manifest.Device.UUID
                    ProfileName = $manifest.Name
                    PageCount = $manifest.Pages.Pages.Count
                    KeyCount = switch ($manifest.Device.Model) {
                        "20GAI9901" { 15 }  # MK.2
                        "20GBD9901" { 32 }  # XL
                        "20GBA9901" { 15 }  # Plus (with dials)
                        "20GAT9901" { 6 }   # Mini
                        default { "Unknown" }
                    }
                    HasDials = ($manifest.Device.Model -eq "20GBA9901")
                }
                
                $devices += $deviceInfo
                Write-Log "Device: $($deviceInfo.ProfileName) - Model: $($deviceInfo.DeviceModel) - Keys: $($deviceInfo.KeyCount)"
            }
        }
    }
    
    return $devices
}

function Get-InstalledPlugins {
    Write-Log "Checking installed plugins..."
    
    $pluginDir = "$env:APPDATA\Elgato\StreamDeck\Plugins"
    $plugins = @()
    
    if (Test-Path $pluginDir) {
        $pluginFolders = Get-ChildItem $pluginDir -Directory
        foreach ($folder in $pluginFolders) {
            $pluginName = $folder.Name -replace '\.sdPlugin$', ''
            $manifestPath = "$($folder.FullName)\manifest.json"
            
            $pluginInfo = @{
                Name = $pluginName
                Folder = $folder.Name
                Path = $folder.FullName
                Version = "Unknown"
                Author = "Unknown"
            }
            
            if (Test-Path $manifestPath) {
                try {
                    $manifest = Get-Content $manifestPath | ConvertFrom-Json
                    $pluginInfo.Version = $manifest.Version
                    $pluginInfo.Author = $manifest.Author
                } catch {
                    Write-Log "Could not read manifest for $pluginName" "WARN"
                }
            }
            
            $plugins += $pluginInfo
            Write-Log "Plugin: $pluginName v$($pluginInfo.Version) by $($pluginInfo.Author)"
        }
    }
    
    return $plugins
}

function Get-MissingEssentialPlugins {
    param([array]$InstalledPlugins)
    
    $essential = @(
        @{ Name = "com.barraider.wintools"; DisplayName = "BarRaider Windows Utils"; Purpose = "System controls, multi-actions, hotkeys" }
        @{ Name = "com.barraider.streamdecktools"; DisplayName = "BarRaider Stream Deck Tools"; Purpose = "Advanced triggers, profiles" }
        @{ Name = "com.barraider.advancedlauncher"; DisplayName = "Advanced Launcher"; Purpose = "App launching with arguments" }
        @{ Name = "com.fredemmott.audiometer"; DisplayName = "Audio Meter"; Purpose = "Visual audio levels" }
        @{ Name = "com.elgato.cpu"; DisplayName = "CPU"; Purpose = "CPU usage display" }
    )
    
    $missing = @()
    foreach ($plugin in $essential) {
        $found = $InstalledPlugins | Where-Object { $_.Name -eq $plugin.Name }
        if (-not $found) {
            $missing += $plugin
        }
    }
    
    return $missing
}

function Export-DetectionReport {
    param(
        [array]$Devices,
        [array]$Plugins,
        [array]$MissingPlugins
    )
    
    $report = @{
        Timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
        Version = $script:Version
        Devices = $Devices
        InstalledPlugins = $Plugins
        MissingEssentialPlugins = $MissingPlugins
        TotalKeys = ($Devices | Measure-Object -Property KeyCount -Sum).Sum
        HasDials = ($Devices | Where-Object { $_.HasDials } | Measure-Object).Count -gt 0
    }
    
    $reportPath = "$env:USERPROFILE\.openclaw\streamdeck-report.json"
    $report | ConvertTo-Json -Depth 10 | Out-File -FilePath $reportPath -Encoding UTF8
    Write-Log "Report saved to: $reportPath"
    
    return $reportPath
}

# Main execution
Write-Log "=== Stream Deck Detection v$script:Version ==="
Write-Log "Starting detection..."

$devices = Get-StreamDeckDevices
$plugins = Get-InstalledPlugins
$missing = Get-MissingEssentialPlugins -InstalledPlugins $plugins

Write-Log ""
Write-Log "=== Detection Summary ==="
Write-Log "Devices found: $($devices.Count)"
Write-Log "Total keys available: $(($devices | Measure-Object -Property KeyCount -Sum).Sum)"
Write-Log "Plugins installed: $($plugins.Count)"
Write-Log "Missing essential plugins: $($missing.Count)"

if ($missing.Count -gt 0) {
    Write-Log ""
    Write-Log "Recommended plugins to install:" "WARN"
    foreach ($plugin in $missing) {
        Write-Log "  - $($plugin.DisplayName): $($plugin.Purpose)" "WARN"
    }
}

$reportPath = Export-DetectionReport -Devices $devices -Plugins $plugins -MissingPlugins $missing

Write-Log ""
Write-Log "Detection complete. Report saved to: $reportPath"

# Return data for other scripts
@{
    Devices = $devices
    Plugins = $plugins
    MissingPlugins = $missing
    ReportPath = $reportPath
}
