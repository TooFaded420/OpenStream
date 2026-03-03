# Generate OpenClaw Profiles for ALL Stream Deck Models
# Creates profiles for: Mini, MK.1, MK.2, Plus, XL, XL Gen 2, Pedal

$OutputDir = "$env:USERPROFILE\.openclaw\streamdeck-profiles"
New-Item -ItemType Directory -Path $OutputDir -Force -ErrorAction SilentlyContinue | Out-Null

# All Stream Deck models with their specs
$StreamDeckModels = @(
    @{ Name = "Mini"; Model = "20GAT9901"; Keys = 6; Dials = 0; Layout = "2x3" }
    @{ Name = "MK1"; Model = "20GAI9901-OLD"; Keys = 15; Dials = 0; Layout = "3x5" }
    @{ Name = "MK2"; Model = "20GAI9901"; Keys = 15; Dials = 0; Layout = "3x5" }
    @{ Name = "Plus"; Model = "20GBA9901"; Keys = 15; Dials = 4; Layout = "3x5+4dials" }
    @{ Name = "XL"; Model = "20GBD9901"; Keys = 32; Dials = 0; Layout = "4x8" }
    @{ Name = "XLGen2"; Model = "20GBD9901-V2"; Keys = 32; Dials = 0; Layout = "4x8" }
    @{ Name = "Pedal"; Model = "20GAP9901"; Keys = 0; Dials = 3; Layout = "3pedals" }
)

# Action definitions
$Actions = @(
    @{ ID = "tts"; Name = "TTS"; Icon = "tts.png"; Desc = "Toggle text-to-speech" }
    @{ ID = "spawn"; Name = "Spawn"; Icon = "spawn.png"; Desc = "Spawn sub-agent" }
    @{ ID = "status"; Name = "Status"; Icon = "status.png"; Desc = "Check OpenClaw status" }
    @{ ID = "models"; Name = "Models"; Icon = "models.png"; Desc = "List AI models" }
    @{ ID = "subagents"; Name = "Subagents"; Icon = "subagents.png"; Desc = "View sub-agents" }
    @{ ID = "nodes"; Name = "Nodes"; Icon = "nodes.png"; Desc = "Node status" }
    @{ ID = "restart"; Name = "Restart"; Icon = "restart.png"; Desc = "Restart gateway" }
    @{ ID = "config"; Name = "Config"; Icon = "config.png"; Desc = "View config" }
    @{ ID = "session"; Name = "Session"; Icon = "session.png"; Desc = "Session info" }
    @{ ID = "websearch"; Name = "Search"; Icon = "websearch.png"; Desc = "Web search" }
    @{ ID = "memory"; Name = "Memory"; Icon = "memory.png"; Desc = "Search memory" }
    @{ ID = "coding"; Name = "Coding"; Icon = "coding.png"; Desc = "Spawn coding agent" }
    @{ ID = "ttsaudio"; Name = "Audio"; Icon = "ttsaudio.png"; Desc = "Send TTS audio" }
    @{ ID = "message"; Name = "Message"; Icon = "message.png"; Desc = "Send message" }
    @{ ID = "browser"; Name = "Browser"; Icon = "browser.png"; Desc = "Open browser" }
)

foreach ($model in $StreamDeckModels) {
    Write-Host "Creating profile for: $($model.Name) ($($model.Keys) keys)" -ForegroundColor Cyan
    
    $profileName = "OpenClaw-$($model.Name)"
    $profileDir = Join-Path $OutputDir "$profileName.sdProfile"
    
    # Skip if already exists (keep user modifications)
    if (Test-Path $profileDir) {
        Write-Host "  Profile already exists, skipping" -ForegroundColor Yellow
        continue
    }
    
    # Create directories
    New-Item -ItemType Directory -Path "$profileDir\Profiles" -Force | Out-Null
    New-Item -ItemType Directory -Path "$profileDir\Images" -Force | Out-Null
    
    # Generate unique IDs
    $profileId = [Guid]::NewGuid().ToString().ToUpper()
    $pageId = [Guid]::NewGuid().ToString()
    
    # Create manifest
    $manifest = @{
        Device = @{
            Model = $model.Model
            UUID = "auto-$profileId"
        }
        Name = $profileName
        Pages = @{
            Current = $pageId
            Default = $pageId
            Pages = @($pageId)
        }
        Version = "2.0"
    }
    $manifest | ConvertTo-Json -Depth 5 | Out-File "$profileDir\manifest.json"
    
    # Select actions based on key count
    $selectedActions = $Actions | Select-Object -First $model.Keys
    
    # Handle special cases
    if ($model.Name -eq "Mini") {
        # Mini only gets 6 most essential actions
        $selectedActions = $Actions | Select-Object -First 6
    }
    elseif ($model.Name -eq "Pedal") {
        # Pedal gets 3 actions (one per pedal)
        $selectedActions = @(
            $Actions[0],  # TTS
            $Actions[1],  # Spawn
            $Actions[2]   # Status
        )
    }
    
    # Build page actions
    $pageActions = @()
    $keyIndex = 0
    foreach ($action in $selectedActions) {
        $pageActions += @{
            Key = $keyIndex
            UUID = "com.openclaw.webhooks.$($action.ID)"
            Name = $action.Name
            Icon = $action.Icon
            States = @(@{
                Image = "images/$($action.Icon)"
                Title = $action.Name
            })
        }
        $keyIndex++
    }
    
    # Create page file
    $pageData = @{
        Controller = ""
        Actions = $pageActions
    }
    $pageData | ConvertTo-Json -Depth 10 | Out-File "$profileDir\Profiles\$pageId.json"
    
    # Create README for this profile
    $readme = @"
# OpenClaw Profile for Stream Deck $($model.Name)

**Device:** $($model.Name) ($($model.Model))
**Layout:** $($model.Layout) ($($model.Keys) keys$(if($model.Dials -gt 0){" + $($model.Dials) dials"}))

## Buttons

| Key | Action | Description |
|-----|--------|-------------|
$(foreach($a in $selectedActions){"| $($keyIndex++) | $($a.Name) | $($a.Desc) |`n"})

## Installation

1. Open Stream Deck software
2. Profile → Import
3. Select this folder
4. Copy icons from assets/icons/ to the Images folder

## Notes
$(if($model.Name -eq "Plus"){"The 4 dials control: Volume, Brightness, Zoom, Scroll`n"}elseif($model.Name -eq "Pedal"){"Pedals are mapped to the 3 actions above`n"}else{"`n"})
---
Generated by OpenClaw Stream Deck Skill
"@
    
    $readme | Out-File "$profileDir\README.txt"
    
    Write-Host "  ✓ Created: $profileName" -ForegroundColor Green
}

Write-Host ""
Write-Host "All profiles created!" -ForegroundColor Green
Write-Host "Location: $OutputDir" -ForegroundColor Cyan
Write-Host ""

# Show summary
Get-ChildItem $OutputDir -Filter "OpenClaw-*.sdProfile" | ForEach-Object {
    $manifest = Get-Content "$($_.FullName)\manifest.json" | ConvertFrom-Json
    Write-Host "  ✓ $($_.Name): $($manifest.Name)" -ForegroundColor White
}
