# Create OpenClaw Live v4 Auto-Profile for Stream Deck
$profileName = "OpenClaw Live v4"
$profileId = "com.openclaw.streamdeck.v4.profile"
$pluginUuid = "com.openclaw.streamdeck.v4"

# Stream Deck profiles directory
$profilesDir = "$env:APPDATA\Elgato\StreamDeck\Profiles"
$profilePath = "$profilesDir\$profileId.json"

# Create profile JSON with all buttons pre-configured
$profile = @{
    Name = $profileName
    UUID = $profileId
    Version = "1.0"
    DeviceType = "StreamDeckMK2"  # Works for MK.2, XL, Plus
    # 15-button layout (3x5 for MK.2, scales to XL)
    Buttons = @(
        # Row 1
        @{ Position = 0; Action = "tts"; Title = "TTS"; Icon = "tts.png" },
        @{ Position = 1; Action = "spawn"; Title = "Spawn"; Icon = "spawn.png" },
        @{ Position = 2; Action = "identity"; Title = "Identity"; Icon = "status.png" },
        @{ Position = 3; Action = "status"; Title = "Status"; Icon = "status.png" },
        @{ Position = 4; Action = "demo-toggle"; Title = "Demo"; Icon = "config.png" },
        # Row 2
        @{ Position = 5; Action = "subagents"; Title = "Agents"; Icon = "subagents.png" },
        @{ Position = 6; Action = "nodes"; Title = "Nodes"; Icon = "nodes.png" },
        @{ Position = 7; Action = "session"; Title = "Session"; Icon = "session.png" },
        @{ Position = 8; Action = "websearch"; Title = "Search"; Icon = "websearch.png" },
        @{ Position = 9; Action = "reconnect"; Title = "Reconnect"; Icon = "restart.png" }
    )
} | ConvertTo-Json -Depth 5

# Save profile
$profile | Out-File -FilePath $profilePath -Encoding UTF8

Write-Host "Profile created: $profilePath" -ForegroundColor Green
Write-Host "Restart Stream Deck to see '$profileName' profile" -ForegroundColor Cyan
