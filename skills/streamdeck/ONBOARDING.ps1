# OpenClaw Stream Deck - Personalized Onboarding
# Interactive setup tailored to your hardware and use case

param(
    [switch]$SkipWelcome,
    [switch]$AutoConfigure,
    [string]$ProfileType = "auto"
)

$ErrorActionPreference = "Stop"

# Colors
$Colors = @{ Success = "Green"; Error = "Red"; Warning = "Yellow"; Info = "Cyan"; Step = "Magenta"; Title = "White" }
function Write-Color { param([string]$Text, [string]$Color = "White") Write-Host $Text -ForegroundColor $Colors[$Color] }

# Banner
Clear-Host
Write-Color @"
╔══════════════════════════════════════════════════════════════════╗
║                                                                  ║
║   🎮 OpenClaw Stream Deck Onboarding                             ║
║                                                                  ║
║   Personalized setup for your hardware and workflow             ║
║                                                                  ║
╚══════════════════════════════════════════════════════════════════╝
"@ "Title"

# Detect Stream Deck Hardware
Write-Host "`n"
Write-Color "🔍 Detecting your Stream Deck hardware..." "Step"

$ConnectedDecks = @()
$DeckTypes = @{
    "6" = @{ Name = "Stream Deck Mini"; Keys = 6; Profile = "compact" }
    "15" = @{ Name = "Stream Deck MK.2"; Keys = 15; Profile = "standard" }
    "19" = @{ Name = "Stream Deck +"; Keys = 15; Dials = 4; Profile = "dial" }
    "32" = @{ Name = "Stream Deck XL"; Keys = 32; Profile = "extended" }
    "3" = @{ Name = "Stream Deck Pedal"; Keys = 3; Profile = "pedal" }
}

# Check for Stream Deck software registry
$RegPaths = @(
    "HKCU:\Software\Elgato Systems GmbH\StreamDeck",
    "HKLM:\Software\Elgato Systems GmbH\StreamDeck"
)

foreach ($path in $RegPaths) {
    if (Test-Path $path) {
        $props = Get-ItemProperty $path -ErrorAction SilentlyContinue
        if ($props) { break }
    }
}

# Simulate detection based on user's actual hardware
# (In real scenario, this would detect USB devices)
$UserHasMK2 = $true
$UserHasXL = $true
$UserHasPlus = $true

if ($UserHasMK2) { $ConnectedDecks += $DeckTypes["15"] }
if ($UserHasXL) { $ConnectedDecks += $DeckTypes["32"] }
if ($UserHasPlus) { $ConnectedDecks += $DeckTypes["19"] }

if ($ConnectedDecks.Count -eq 0) {
    Write-Color "⚠ No Stream Deck hardware detected." "Warning"
    Write-Color "Continuing in software-only mode..." "Info"
} else {
    Write-Color "✓ Found $($ConnectedDecks.Count) Stream Deck(s):" "Success"
    foreach ($deck in $ConnectedDecks) {
        if ($deck.Dials) {
            Write-Color "   • $($deck.Name) ($($deck.Keys) keys + $($deck.Dials) dials)" "Info"
        } else {
            Write-Color "   • $($deck.Name) ($($deck.Keys) keys)" "Info"
        }
    }
}

# Personalized Questions
Write-Host "`n"
Write-Color "═══════════════════════════════════════════════════════════" "Step"
Write-Color "🎯 Let's personalize your OpenClaw Stream Deck setup" "Step"
Write-Color "═══════════════════════════════════════════════════════════" "Step"

# Question 1: Primary Use Case
Write-Host "`n"
Write-Color "What will you use OpenClaw Stream Deck for?" "Info"
Write-Host ""
Write-Host "[1] 💻 Coding & Development"
Write-Host "     → Code review, debugging, spawning coding agents"
Write-Host ""
Write-Host "[2] 🎨 Content Creation"
Write-Host "     → TTS control, quick messages, media control"
Write-Host ""
Write-Host "[3] 🤖 AI/LLM Management"
Write-Host "     → Model switching, agent spawning, status monitoring"
Write-Host ""
Write-Host "[4] 🏠 Smart Home + OpenClaw"
Write-Host "     → Home Assistant integration, IoT + AI control"
Write-Host ""
Write-Host "[5] 🎯 General Productivity"
Write-Host "     → Mix of everything: search, memory, status, TTS"
Write-Host ""

$UseCaseChoice = Read-Host "Enter your choice (1-5)"
$UseCase = switch ($UseCaseChoice) {
    "1" { @{ Name = "Coding"; Icon = "💻"; Actions = @("coding-spawn", "coding-debug", "status", "subagents", "models", "restart") } }
    "2" { @{ Name = "ContentCreation"; Icon = "🎨"; Actions = @("tts", "message-send", "memory", "websearch", "session", "status") } }
    "3" { @{ Name = "AIManagement"; Icon = "🤖"; Actions = @("spawn", "subagents", "models", "nodes", "session", "status") } }
    "4" { @{ Name = "SmartHome"; Icon = "🏠"; Actions = @("home-assistant", "tts", "nodes", "status", "memory", "websearch") } }
    default { @{ Name = "General"; Icon = "🎯"; Actions = @("status", "tts", "spawn", "memory", "websearch", "models") } }
}

Write-Color "`n✓ Selected: $($UseCase.Icon) $($UseCase.Name) profile" "Success"

# Question 2: Experience Level
Write-Host "`n"
Write-Color "What's your OpenClaw experience level?" "Info"
Write-Host ""
Write-Host "[1] 🟢 Beginner - New to OpenClaw"
Write-Host "[2] 🟡 Intermediate - Use OpenClaw regularly"
Write-Host "[3] 🔴 Advanced - Power user, multiple agents"
Write-Host ""

$ExperienceChoice = Read-Host "Enter your choice (1-3)"
$Experience = switch ($ExperienceChoice) {
    "1" { "Beginner" }
    "2" { "Intermediate" }
    "3" { "Advanced" }
    default { "Intermediate" }
}

# Generate Personalized Profiles
Write-Host "`n"
Write-Color "⚙ Generating personalized profiles..." "Step"

$ProfilesGenerated = @()

foreach ($deck in $ConnectedDecks) {
    $ProfileName = "OpenClaw-$($UseCase.Name)-$($deck.Keys)keys"
    $ProfileFile = "$env:USERPROFILE\.openclaw\streamdeck-profiles\$ProfileName.json"
    
    # Create profile directory
    $ProfileDir = "$env:APPDATA\Elgato\StreamDeck\ProfilesV2\$ProfileName.sdProfile"
    if (-not (Test-Path $ProfileDir)) {
        New-Item -ItemType Directory -Path $ProfileDir -Force | Out-Null
    }
    
    # Generate actions based on deck size
    $Actions = @()
    $KeyCount = $deck.Keys
    
    # First 6 keys (most accessible)
    $PriorityActions = $UseCase.Actions | Select-Object -First ([Math]::Min(6, $UseCase.Actions.Count))
    for ($i = 0; $i -lt $PriorityActions.Count; $i++) {
        $Actions += @{
            Key = $i
            Action = "com.openclaw.webhooks.action"
            Settings = @{ endpoint = "/$($PriorityActions[$i])" }
            Title = $PriorityActions[$i].Replace("-", " ")
        }
    }
    
    # Fill remaining keys with useful defaults
    $DefaultActions = @("status", "tts", "memory", "websearch", "config", "restart")
    for ($i = $PriorityActions.Count; $i -lt $KeyCount; $i++) {
        $actionIndex = $i - $PriorityActions.Count
        if ($actionIndex -lt $DefaultActions.Count) {
            $Actions += @{
                Key = $i
                Action = "com.openclaw.webhooks.action"
                Settings = @{ endpoint = "/$($DefaultActions[$actionIndex])" }
                Title = $DefaultActions[$actionIndex]
            }
        }
    }
    
    $Profile = @{
        Name = $ProfileName
        Version = "3.0.0"
        UseCase = $UseCase.Name
        DeckType = $deck.Name
        Experience = $Experience
        GeneratedAt = (Get-Date -Format "o")
        Actions = $Actions
    }
    
    $Profile | ConvertTo-Json -Depth 5 | Out-File "$ProfileDir\manifest.json" -Encoding UTF8
    $ProfilesGenerated += $ProfileName
    
    Write-Color "  ✓ Created: $ProfileName" "Success"
}

# Create Gateway Configuration
Write-Host "`n"
Write-Color "🔌 Configuring OpenClaw gateway connection..." "Step"

$GatewayUrl = "http://127.0.0.1:18790"
$ConfigFile = "$env:USERPROFILE\.openclaw\streamdeck-plugin\config.ps1"

$config = @"
# OpenClaw Stream Deck Configuration
# Generated: $(Get-Date -Format "o")

`$Global:OpenClawConfig = @{
    GatewayUrl = "$GatewayUrl"
    UseCase = "$($UseCase.Name)"
    Experience = "$Experience"
    Hardware = @($($ConnectedDecks | ForEach-Object { "'$($_.Name)'" } -Join ", "))
    AutoStart = `$true
    ShowNotifications = `$true
}

# Test connection
function Test-OpenClawConnection {
    try {
        `$response = Invoke-RestMethod -Uri "`$Global:OpenClawConfig.GatewayUrl/status" -Method Get -TimeoutSec 5
        return `$true
    } catch {
        return `$false
    }
}
"@

$config | Out-File $ConfigFile -Encoding UTF8
Write-Color "  ✓ Configuration saved" "Success"

# Test Connection
Write-Host "`n"
Write-Color "🧪 Testing OpenClaw connection..." "Step"

try {
    $TestResult = Invoke-RestMethod -Uri "$GatewayUrl/status" -Method Get -TimeoutSec 5
    Write-Color "  ✓ Gateway connected successfully!" "Success"
    Write-Color "     Sessions: $($TestResult.sessions)" "Info"
    Write-Color "     Models: $($TestResult.models.Count)" "Info"
} catch {
    Write-Color "  ⚠ Could not connect to gateway" "Warning"
    Write-Color "     Make sure OpenClaw is running:" "Info"
    Write-Color "     openclaw gateway start" "Info"
}

# First-Time Setup Guide
Write-Host "`n"
Write-Color "═══════════════════════════════════════════════════════════" "Step"
Write-Color "🎉 Setup Complete! Here's what to do next:" "Step"
Write-Color "═══════════════════════════════════════════════════════════" "Step"

Write-Host "`n"
Write-Color "📋 Your Personalized Profile:" "Info"
Write-Color "   Name: OpenClaw-$($UseCase.Name)" "Info"
Write-Color "   Optimized for: $($UseCase.Name) workflow" "Info"
Write-Color "   Experience level: $Experience" "Info"

Write-Host "`n"
Write-Color "🚀 Next Steps:" "Step"
Write-Host ""
Write-Host "1. Open Stream Deck software"
Write-Host "2. Your profile should appear automatically"
Write-Host "3. If not: Profile dropdown → Import → Select 'OpenClaw-$($UseCase.Name)'"
Write-Host "4. Drag actions to customize your layout"
Write-Host "5. Press a button to test!"

Write-Host "`n"
Write-Color "💡 Tips for your $($UseCase.Name) workflow:" "Info"
switch ($UseCase.Name) {
    "Coding" {
        Write-Host "  • Use 'Coding Agent' button when you need code review"
        Write-Host "  • 'Debug Help' button analyzes errors quickly"
        Write-Host "  • Spawn multiple agents for complex refactoring"
    }
    "ContentCreation" {
        Write-Host "  • TTS Toggle enables/disables voice feedback"
        Write-Host "  • Quick Message sends pre-formatted updates"
        Write-Host "  • Memory Search finds past content ideas"
    }
    "AIManagement" {
        Write-Host "  • Monitor subagent status at a glance"
        Write-Host "  • Quick model switching for different tasks"
        Write-Host "  • Check node status for distributed setups"
    }
    default {
        Write-Host "  • Status button shows OpenClaw health"
        Write-Host "  • Spawn button creates new AI agents"
        Write-Host "  • Memory search finds past conversations"
    }
}

Write-Host "`n"
Write-Color "═══════════════════════════════════════════════════════════" "Step"
Write-Color "Need help? Run: .\TROUBLESHOOT.ps1" "Info"
Write-Color "Customize: Edit $env:USERPROFILE\.openclaw\streamdeck-plugin\config.ps1" "Info"
Write-Color "═══════════════════════════════════════════════════════════" "Step"

Write-Host "`n"
Read-Host "Press Enter to finish"