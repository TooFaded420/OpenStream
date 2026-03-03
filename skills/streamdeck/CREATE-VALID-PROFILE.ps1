# Create Valid Stream Deck Profile
# Creates a properly formatted profile that Stream Deck will recognize

$ProfileName = "OpenClaw-Working"
$ProfilePath = "$env:APPDATA\Elgato\StreamDeck\ProfilesV2\$ProfileName.sdProfile"

# Create profile directory
if (Test-Path $ProfilePath) {
    Remove-Item $ProfilePath -Recurse -Force
}
New-Item -ItemType Directory -Path $ProfilePath -Force | Out-Null

# Create proper manifest
$manifest = @{
    Name = $ProfileName
    UUID = [guid]::NewGuid().ToString()
    Version = "3.0.0"
    Device = @{
        UUID = [guid]::NewGuid().ToString()
        Model = "20GAI9901"
        Name = "Stream Deck MK.2"
    }
    Icon = "Default"
    Pages = @(
        @{
            UUID = [guid]::NewGuid().ToString()
            Name = "Page 1"
            Keys = @(
                @{
                    UUID = [guid]::NewGuid().ToString()
                    Title = "Switch GW"
                    Icon = "Default"
                    Action = @{ UUID = "com.openclaw.webhooks.action" }
                    Settings = @{ endpoint = "/gateway-switch"; gatewayKey = "primary" }
                },
                @{
                    UUID = [guid]::NewGuid().ToString()
                    Title = "Spawn Agent"
                    Icon = "Default"
                    Action = @{ UUID = "com.openclaw.webhooks.action" }
                    Settings = @{ endpoint = "/spawn"; gatewayKey = "primary" }
                },
                @{
                    UUID = [guid]::NewGuid().ToString()
                    Title = "Status"
                    Icon = "Default"
                    Action = @{ UUID = "com.openclaw.webhooks.action" }
                    Settings = @{ endpoint = "/status"; gatewayKey = "primary" }
                },
                @{
                    UUID = [guid]::NewGuid().ToString()
                    Title = "Models"
                    Icon = "Default"
                    Action = @{ UUID = "com.openclaw.webhooks.action" }
                    Settings = @{ endpoint = "/models"; gatewayKey = "primary" }
                },
                @{
                    UUID = [guid]::NewGuid().ToString()
                    Title = "TTS"
                    Icon = "Default"
                    Action = @{ UUID = "com.openclaw.webhooks.action" }
                    Settings = @{ endpoint = "/tts.toggle"; gatewayKey = "primary" }
                },
                @{
                    UUID = [guid]::NewGuid().ToString()
                    Title = "Nodes"
                    Icon = "Default"
                    Action = @{ UUID = "com.openclaw.webhooks.action" }
                    Settings = @{ endpoint = "/nodes"; gatewayKey = "primary" }
                },
                @{
                    UUID = [guid]::NewGuid().ToString()
                    Title = "Restart"
                    Icon = "Default"
                    Action = @{ UUID = "com.openclaw.webhooks.action" }
                    Settings = @{ endpoint = "/gateway.restart"; gatewayKey = "primary" }
                },
                @{
                    UUID = [guid]::NewGuid().ToString()
                    Title = "Config"
                    Icon = "Default"
                    Action = @{ UUID = "com.openclaw.webhooks.action" }
                    Settings = @{ endpoint = "/config"; gatewayKey = "primary" }
                },
                @{
                    UUID = [guid]::NewGuid().ToString()
                    Title = "Session"
                    Icon = "Default"
                    Action = @{ UUID = "com.openclaw.webhooks.action" }
                    Settings = @{ endpoint = "/session"; gatewayKey = "primary" }
                },
                @{
                    UUID = [guid]::NewGuid().ToString()
                    Title = "Memory"
                    Icon = "Default"
                    Action = @{ UUID = "com.openclaw.webhooks.action" }
                    Settings = @{ endpoint = "/memory_search"; gatewayKey = "primary" }
                },
                @{
                    UUID = [guid]::NewGuid().ToString()
                    Title = "Search"
                    Icon = "Default"
                    Action = @{ UUID = "com.openclaw.webhooks.action" }
                    Settings = @{ endpoint = "/web.search"; gatewayKey = "primary" }
                },
                @{
                    UUID = [guid]::NewGuid().ToString()
                    Title = "Code"
                    Icon = "Default"
                    Action = @{ UUID = "com.openclaw.webhooks.action" }
                    Settings = @{ endpoint = "/coding-spawn"; gatewayKey = "primary" }
                },
                @{
                    UUID = [guid]::NewGuid().ToString()
                    Title = "Debug"
                    Icon = "Default"
                    Action = @{ UUID = "com.openclaw.webhooks.action" }
                    Settings = @{ endpoint = "/coding-debug"; gatewayKey = "primary" }
                },
                @{
                    UUID = [guid]::NewGuid().ToString()
                    Title = "Message"
                    Icon = "Default"
                    Action = @{ UUID = "com.openclaw.webhooks.action" }
                    Settings = @{ endpoint = "/message.send"; gatewayKey = "primary" }
                },
                @{
                    UUID = [guid]::NewGuid().ToString()
                    Title = "Browser"
                    Icon = "Default"
                    Action = @{ UUID = "com.openclaw.webhooks.action" }
                    Settings = @{ endpoint = "/browser"; gatewayKey = "primary" }
                }
            )
        }
    )
}

# Save manifest
$manifest | ConvertTo-Json -Depth 10 | Out-File "$ProfilePath\manifest.json" -Encoding UTF8

# Create empty images folder
New-Item -ItemType Directory -Path "$ProfilePath\Images" -Force | Out-Null

Write-Host ""
Write-Host "================================" -ForegroundColor Green
Write-Host "Valid Profile Created!" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Green
Write-Host ""
Write-Host "Profile: $ProfileName" -ForegroundColor White
Write-Host "Location: $ProfilePath" -ForegroundColor Gray
Write-Host ""
Write-Host "RESTART Stream Deck and look for '$ProfileName' in profile dropdown!" -ForegroundColor Yellow