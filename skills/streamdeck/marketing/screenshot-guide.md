# Store Screenshots for Elgato Marketplace

## Required Images

### 1. Hero Image (1280x800)
**Purpose:** Main store banner
**Content:**
- Stream Deck with OpenClaw icons prominently displayed
- OpenClaw branding (coral red #ff5c5c)
- Clean, modern look
- Shows 6-8 buttons with icons
- Text overlay: "Control Your AI Assistant"
- Background: Dark gradient (#12141a to #1a1d25)

**To Create:**
```powershell
# Use existing icons, arrange in grid
# Add text overlay with PowerShell + System.Drawing
# Or use Canva/Figma template
```

### 2. Screenshot 1 - Main View (1280x720)
**Title:** "Your AI Command Center"
**Content:**
- Split screen: Stream Deck software + OpenClaw chat
- Shows buttons being pressed
- Shows OpenClaw responding
- Caption: "Spawn agents, toggle TTS, check status - all from your Stream Deck"

### 3. Screenshot 2 - Actions List (1280x720)
**Title:** "25+ Built-in Actions"
**Content:**
- List of available actions in Stream Deck software
- Categories: Core, Coding, Messaging, System
- Shows the variety of buttons
- Caption: "Pre-built actions for every use case"

### 4. Screenshot 3 - Settings (1280x720)
**Title:** "Easy Configuration"
**Content:**
- Property inspector showing settings
- Gateway URL field
- Device token field
- Simple, clean UI
- Caption: "Connect in seconds"

### 5. Screenshot 4 - Multi-Gateway (1280x720)
**Title:** "Multi-Device Support"
**Content:**
- Shows 2-3 Stream Decks
- Shows connection to multiple OpenClaw instances
- Network diagram style
- Caption: "Control multiple OpenClaw gateways"

## Technical Specs

| Image | Size | Format | Max Size |
|-------|------|--------|----------|
| Hero | 1280x800 | PNG/JPG | 2MB |
| Screenshots | 1280x720 | PNG/JPG | 1MB each |
| Icon | 512x512 | PNG | 500KB |

## Quick Creation Guide

### Using PowerShell:
```powershell
Add-Type -AssemblyName System.Drawing

# Create hero image
$width = 1280
$height = 800
$bmp = New-Object System.Drawing.Bitmap($width, $height)
$g = [System.Drawing.Graphics]::FromImage($bmp)

# Background gradient
$brush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
    [System.Drawing.Rectangle]::new(0, 0, $width, $height),
    [System.Drawing.Color]::FromArgb(18, 20, 26),
    [System.Drawing.Color]::FromArgb(26, 29, 37),
    45
)
$g.FillRectangle($brush, 0, 0, $width, $height)

# Add text
$font = New-Object System.Drawing.Font("Segoe UI", 48, [System.Drawing.FontStyle]::Bold)
$brushText = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 92, 92))
$g.DrawString("Control Your AI", $font, $brushText, 400, 300)
$g.DrawString("From Stream Deck", $font, $brushText, 400, 380)

# Save
$bmp.Save("$env:USERPROFILE\Desktop\hero-screenshot.png")
```

### Using Figma (Recommended):
1. Create frame: 1280x800
2. Import Stream Deck image
3. Add OpenClaw icons
4. Add text with coral red color
5. Export as PNG

### Using Canva:
1. Custom size: 1280x800
2. Dark background (#12141a)
3. Add Stream Deck mockup
4. Add OpenClaw branding
5. Export PNG

## Screenshot Checklist

- [ ] Hero image created (1280x800)
- [ ] Screenshot 1 - Main view (1280x720)
- [ ] Screenshot 2 - Actions list (1280x720)
- [ ] Screenshot 3 - Settings (1280x720)
- [ ] Screenshot 4 - Multi-gateway (1280x720)
- [ ] Plugin icon (512x512)
- [ ] All files under size limits
- [ ] Images tested on store preview

## Store Preview Text

**Short Description:**
"Control your OpenClaw AI assistant from Stream Deck. 25+ actions, multi-gateway support, dynamic status."

**Keywords:**
openclaw, ai, stream deck, assistant, agent, automation

---
**Save screenshots to:** `assets/store-screenshots/`
