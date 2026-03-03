# Stream Deck Profile Generator for OpenClaw
# Generates profile JSON files for Stream Deck

$script:Version = "1.0.0"

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp [$Level] $Message" | Write-Host
}

function New-OpenClawProfile {
    param(
        [string]$ProfileName = "OpenClaw Control",
        [string]$DeviceModel = "20GAI9901",
        [string]$OutputDir = "$env:USERPROFILE\.openclaw\streamdeck-profiles"
    )
    
    Write-Log "Creating OpenClaw profile: $ProfileName"
    
    # Determine key count based on device model
    $keyCount = switch ($DeviceModel) {
        "20GAI9901" { 15 }  # MK.2
        "20GBD9901" { 32 }  # XL
        "20GBA9901" { 15 }  # Plus
        "20GAT9901" { 6 }   # Mini
        default { 15 }
    }
    
    # Create profile directory
    $profileId = [Guid]::NewGuid().ToString().ToUpper()
    $profileDir = Join-Path $OutputDir "$profileId.sdProfile"
    $profilesDir = Join-Path $profileDir "Profiles"
    $imagesDir = Join-Path $profileDir "Images"
    
    New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
    New-Item -ItemType Directory -Path $profilesDir -Force | Out-Null
    New-Item -ItemType Directory -Path $imagesDir -Force | Out-Null
    
    Write-Log "Profile directory: $profileDir"
    
    # Create manifest
    $pageId = [Guid]::NewGuid().ToString()
    $manifest = @{
        Device = @{
            Model = $DeviceModel
            UUID = "@generated-$profileId"
        }
        Name = $ProfileName
        Pages = @{
            Current = $pageId
            Default = $pageId
            Pages = @($pageId)
        }
        Version = "2.0"
    }
    
    $manifest | ConvertTo-Json -Depth 5 | Out-File (Join-Path $profileDir "manifest.json") -Encoding UTF8
    
    # Define OpenClaw actions based on key count
    $actions = @()
    
    # Base actions for all layouts
    $baseActions = @(
        @{
            Name = "TTS Toggle"
            Icon = "🔊"
            Action = "tts.toggle"
            Key = 0
        }
        @{
            Name = "Spawn Agent"
            Icon = "🤖"
            Action = "spawn.quick"
            Key = 1
        }
        @{
            Name = "Status"
            Icon = "📊"
            Action = "status.check"
            Key = 2
        }
        @{
            Name = "Models"
            Icon = "🧠"
            Action = "models.list"
            Key = 3
        }
        @{
            Name = "Subagents"
            Icon = "⚡"
            Action = "subagents.list"
            Key = 4
        }
    )
    
    # Additional actions for larger decks
    $extraActions = @(
        @{
            Name = "Node Status"
            Icon = "📡"
            Action = "nodes.status"
            Key = 5
        }
        @{
            Name = "Restart Gateway"
            Icon = "🔄"
            Action = "gateway.restart"
            Key = 6
        }
        @{
            Name = "Config Get"
            Icon = "⚙️"
            Action = "config.get"
            Key = 7
        }
        @{
            Name = "Session Status"
            Icon = "💬"
            Action = "session.status"
            Key = 8
        }
        @{
            Name = "Web Search"
            Icon = "🔍"
            Action = "web.search"
            Key = 9
        }
        @{
            Name = "Memory Search"
            Icon = "🧠"
            Action = "memory.search"
            Key = 10
        }
        @{
            Name = "Spawn Coding"
            Icon = "💻"
            Action = "spawn.coding"
            Key = 11
        }
        @{
            Name = "TTS Audio"
            Icon = "🎙️"
            Action = "tts.audio"
            Key = 12
        }
        @{
            Name = "Message Send"
            Icon = "📤"
            Action = "message.send"
            Key = 13
        }
        @{
            Name = "Browser"
            Icon = "🌐"
            Action = "browser.open"
            Key = 14
        }
    )
    
    # Combine actions based on key count
    $allActions = $baseActions
    if ($keyCount -gt 5) {
        $allActions += $extraActions | Select-Object -First ($keyCount - 5)
    }
    
    # Generate action JSON for Stream Deck
    $pageActions = @()
    foreach ($actionDef in $allActions) {
        $action = @{
            Key = $actionDef.Key
            UUID = "com.openclaw.webhooks.$($actionDef.Action)"
            Icon = $actionDef.Icon
            Name = $actionDef.Name
            States = @(
                @{
                    Image = "images/$($actionDef.Action).png"
                    Title = $actionDef.Name
                }
            )
        }
        $pageActions += $action
    }
    
    $pageFile = @{
        Controller = ""
        Actions = $pageActions
    }
    
    $pageFile | ConvertTo-Json -Depth 10 | Out-File (Join-Path $profilesDir "$pageId.json") -Encoding UTF8
    
    Write-Log "Created profile with $($pageActions.Count) actions"
    
    # Create placeholder icon files (user would replace these)
    foreach ($action in $allActions) {
        # Create empty PNG placeholder
        $iconPath = Join-Path $imagesDir "$($action.Action).png"
        # In a real implementation, we'd generate actual icons
        "# Placeholder for $($action.Name) icon" | Out-File "$iconPath.txt" -Encoding UTF8
    }
    
    Write-Log "Profile created successfully at: $profileDir"
    
    return $profileDir
}

function Export-ProfileInstructions {
    param([string]$OutputPath = "$env:USERPROFILE\.openclaw\streamdeck-profile-setup.md")
    
    $instructions = @"
# Stream Deck OpenClaw Profile Setup

## Installation Instructions

### Method 1: Manual Import

1. Open Stream Deck software
2. Click the profile dropdown (top left)
3. Select "Import Profile"
4. Navigate to the generated .sdProfile folder
5. Select the profile to import

### Method 2: Direct Copy

1. Copy the generated profile folder to:
   ``%APPDATA%\Elgato\StreamDeck\ProfilesV2\``
2. Restart Stream Deck software
3. The profile will appear in your profile list

## Button Reference

| Position | Action | Description |
|----------|--------|-------------|
| 1 | TTS Toggle | Enable/disable TTS |
| 2 | Spawn Agent | Quick spawn a sub-agent |
| 3 | Status | Check OpenClaw status |
| 4 | Models | List available models |
| 5 | Subagents | List active subagents |
| 6 | Node Status | Check paired nodes |
| 7 | Restart Gateway | Restart OpenClaw gateway |
| 8 | Config | View current config |
| 9 | Session Status | Current session info |
| 10 | Web Search | Quick web search |
| 11 | Memory Search | Search memory |
| 12 | Spawn Coding | Spawn coding agent |
| 13 | TTS Audio | Send TTS audio |
| 14 | Message | Send message |
| 15 | Browser | Open browser |

## Customizing Icons

Replace the placeholder files in the Images folder with your own PNG icons:
- Recommended size: 72x72 pixels
- Format: PNG with transparency
- Use high contrast for visibility

## Troubleshooting

**Buttons not working?**
- Ensure OpenClaw gateway is running
- Check that the webhook plugin is installed
- Verify the gateway URL in plugin settings

**Profile not showing?**
- Restart Stream Deck software
- Check that the profile folder has correct permissions
- Verify the manifest.json syntax

## Advanced Customization

Edit the JSON files directly to:
- Add multi-actions (button sequences)
- Configure conditional triggers
- Set up profile switching
- Add folder structures for more buttons

## Support

For OpenClaw issues: https://docs.openclaw.ai
For Stream Deck issues: https://help.elgato.com
"@
    
    $instructions | Out-File $OutputPath -Encoding UTF8
    Write-Log "Instructions saved to: $OutputPath"
    
    return $OutputPath
}

# Main execution
Write-Log "=== Stream Deck Profile Generator v$script:Version ==="

# Check for device detection report
$reportPath = "$env:USERPROFILE\.openclaw\streamdeck-report.json"
$deviceModel = "20GAI9901"  # Default to MK.2

if (Test-Path $reportPath) {
    $report = Get-Content $reportPath | ConvertFrom-Json
    if ($report.Devices.Count -gt 0) {
        $deviceModel = $report.Devices[0].DeviceModel
        Write-Log "Detected device model: $deviceModel"
    }
}

# Create profiles directory
$outputDir = "$env:USERPROFILE\.openclaw\streamdeck-profiles"
New-Item -ItemType Directory -Path $outputDir -Force | Out-Null

# Generate profile
$profilePath = New-OpenClawProfile -DeviceModel $deviceModel -OutputDir $outputDir

# Export instructions
$instructionsPath = Export-ProfileInstructions

Write-Log ""
Write-Log "=== Generation Complete ==="
Write-Log "Profile: $profilePath"
Write-Log "Instructions: $instructionsPath"

# Return results
@{
    ProfilePath = $profilePath
    InstructionsPath = $instructionsPath
    DeviceModel = $deviceModel
}
