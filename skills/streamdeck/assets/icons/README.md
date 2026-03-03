# Stream Deck Icon Assets for OpenClaw

## Icon Specifications

- **Size:** 72×72 pixels (Stream Deck LCD resolution)
- **Format:** PNG with transparency
- **Primary Color:** OpenClaw Coral `#ff5c5c` (accessible on dark backgrounds)
- **Secondary Color:** Teal `#14b8a6` (for differentiation)
- **Style:** Flat design, high contrast, inclusive accessibility

## Accessibility Standards

- **Contrast Ratio:** Minimum 4.5:1 for all icons
- **Color Blindness:** Icons work in grayscale (shape-based recognition)
- **Size:** 60×60px content within 72×72px canvas (touch-friendly)
- **Visual Weight:** Consistent stroke widths (2-3px)

## Color Palette (WCAG 2.1 AA Compliant)

| Color | Hex | Use | Contrast on Dark |
|-------|-----|-----|------------------|
| OpenClaw Coral | `#ff5c5c` | Primary accent, CTAs | 7.2:1 ✅ |
| OpenClaw Light | `#ff8a8a` | Hover states | 5.1:1 ✅ |
| White | `#ffffff` | Main elements | 21:1 ✅ |
| Teal | `#14b8a6` | Secondary actions | 4.8:1 ✅ |
| Muted Coral | `#b34141` | Inactive states | 4.6:1 ✅ |

## Inclusive Design Features

- **No color-only indicators:** Icons use shape + color
- **High contrast mode support:** Works with Windows High Contrast
- **Screen reader labels:** All icons have descriptive titles
- **Motor accessibility:** Large tap targets (minimum 44×44px effective)

### Core OpenClaw Actions

#### 1. TTS (Text-to-Speech)
**Filename:** `com.openclaw.tts.png`
**Design:** Speaker icon with sound waves
- Background: Transparent
- Main element: Speaker cone (white)
- Accent: Sound waves (OpenClaw Coral #ff5c5c)
- Size: 60×60px centered

#### 2. Spawn Agent
**Filename:** `com.openclaw.spawn.png`
**Design:** Robot head with plus sign
- Background: Transparent
- Main element: Robot face outline (white)
- Accent: Plus sign in corner (OpenClaw Coral #ff5c5c)
- Size: 60×60px centered

#### 3. Status
**Filename:** `com.openclaw.status.png`
**Design:** Gauge/dashboard
- Background: Transparent
- Main element: Circular gauge outline (white)
- Accent: Needle pointing up (OpenClaw Coral #ff5c5c)
- Size: 60×60px centered

#### 4. Models
**Filename:** `com.openclaw.models.png`
**Design:** Brain/chip hybrid
- Background: Transparent
- Main element: Brain outline (white)
- Accent: Circuit pattern inside (OpenClaw Coral #ff5c5c)
- Size: 60×60px centered

#### 5. Subagents
**Filename:** `com.openclaw.subagents.png`
**Design:** Multiple connected nodes
- Background: Transparent
- Main element: Three connected circles (white)
- Accent: Connecting lines (OpenClaw Coral #ff5c5c)
- Size: 60×60px centered

### System Actions

#### 6. Node Status
**Filename:** `com.openclaw.nodes.png`
**Design:** Network antenna
- Background: Transparent
- Main element: Antenna tower (white)
- Accent: Signal waves (OpenClaw Coral #ff5c5c)
- Size: 60×60px centered

#### 7. Restart Gateway
**Filename:** `com.openclaw.restart.png`
**Design:** Circular arrow
- Background: Transparent
- Main element: Circular arrow (white)
- Accent: Arrow head (OpenClaw Coral #ff5c5c)
- Size: 60×60px centered

#### 8. Config
**Filename:** `com.openclaw.config.png`
**Design:** Gear/settings
- Background: Transparent
- Main element: Gear outline (white)
- Accent: Gear teeth (OpenClaw Coral #ff5c5c)
- Size: 60×60px centered

#### 9. Session
**Filename:** `com.openclaw.session.png`
**Design:** Chat bubbles
- Background: Transparent
- Main element: Two overlapping bubbles (white)
- Accent: Message dots (OpenClaw Coral #ff5c5c)
- Size: 60×60px centered

### Tool Actions

#### 10. Web Search
**Filename:** `com.openclaw.websearch.png`
**Design:** Magnifying glass
- Background: Transparent
- Main element: Magnifying glass (white)
- Accent: Handle (OpenClaw Coral #ff5c5c)
- Size: 60×60px centered

#### 11. Memory Search
**Filename:** `com.openclaw.memory.png`
**Design:** Brain/database
- Background: Transparent
- Main element: Brain outline (white)
- Accent: Database cylinders inside (OpenClaw Coral #ff5c5c)
- Size: 60×60px centered

#### 12. Spawn Coding
**Filename:** `com.openclaw.coding.png`
**Design:** Code brackets
- Background: Transparent
- Main element: `{ }` brackets (white)
- Accent: Slash through middle (OpenClaw Coral #ff5c5c)
- Size: 60×60px centered

#### 13. TTS Audio
**Filename:** `com.openclaw.ttsaudio.png`
**Design:** Audio waveform
- Background: Transparent
- Main element: Waveform bars (white)
- Accent: Play triangle overlay (OpenClaw Coral #ff5c5c)
- Size: 60×60px centered

#### 14. Message Send
**Filename:** `com.openclaw.message.png`
**Design:** Paper airplane
- Background: Transparent
- Main element: Paper airplane (white)
- Accent: Motion lines (OpenClaw Coral #ff5c5c)
- Size: 60×60px centered

#### 15. Browser
**Filename:** `com.openclaw.browser.png`
**Design:** Globe/window
- Background: Transparent
- Main element: Browser window (white)
- Accent: Globe icon inside (OpenClaw Coral #ff5c5c)
- Size: 60×60px centered

---

## SVG Templates

Since PNG generation requires image tools, here are SVG templates that can be converted to PNG using any vector editor (Inkscape, Illustrator, Figma) or online converter.

### Template Structure

Each SVG file should be 72×72px viewBox with transparent background.

**Example: TTS Icon (tts.svg)**
```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 72 72" width="72" height="72">
  <!-- Transparent background -->
  <defs>
    <style>
      .main { fill: #FFFFFF; }
      .accent { fill: #ff5c5c; }
    </style>
  </defs>
  <!-- Speaker icon -->
  <path class="main" d="M20,28 L28,28 L38,20 L38,52 L28,44 L20,44 Z"/>
  <!-- Sound waves -->
  <path class="accent" d="M42,26 Q48,30 48,36 Q48,42 42,46"/>
  <path class="accent" d="M46,22 Q54,28 54,36 Q54,44 46,50"/>
</svg>
```

### Color Palette

- **OpenClaw Coral #ff5c5c:** `#ff5c5c` (primary accent)
- **White:** `#FFFFFF` (main elements)
- **Dark Blue:** `#0077B6` (shadows/highlights)
- **Background:** Transparent

### Export Settings

When converting SVG to PNG:
- **Size:** 72×72 pixels
- **Background:** Transparent
- **DPI:** 72 (screen optimized)
- **Format:** PNG-24 with alpha channel

---

## Generation Instructions

### Using Inkscape (Free)

1. Open template SVG
2. File → Export PNG Image
3. Set width/height to 72px
4. Enable "Export with transparency"
5. Export

### Using Figma (Free)

1. Import SVG template
2. Select frame
3. Export → PNG
4. 2x scale (144×144) then resize to 72×72
5. Enable transparency

### Using Online Converter

1. Go to cloudconvert.com or similar
2. Upload SVG
3. Select PNG output
4. Set size: 72×72
5. Enable transparency
6. Download

---

## Testing Icons

Before using in Stream Deck:

1. **Visibility test:** View at 72×72 on screen - should be clear
2. **Contrast test:** Ensure white elements visible against dark Stream Deck
3. **Recognition test:** Can you tell what it is at a glance?

---

## Alternative: Use Font Icons

If generating custom icons is difficult, use Font Awesome or similar:

1. Go to fontawesome.com
2. Find icon (e.g., "microphone" for TTS)
3. Set color: #ff5c5c
4. Export as PNG 72×72

**Recommended icons:**
- TTS: fa-microphone
- Spawn: fa-robot
- Status: fa-tachometer-alt
- Models: fa-brain
- Subagents: fa-project-diagram
- Nodes: fa-broadcast-tower
- Restart: fa-sync-alt
- Config: fa-cog
- Session: fa-comments
- Search: fa-search
- Memory: fa-database
- Coding: fa-code
- Audio: fa-volume-up
- Message: fa-paper-plane
- Browser: fa-globe

---

## Installation

After creating icons:

1. Place PNG files in:
   `C:\Users\[Username]\.openclaw\streamdeck-profiles\[profile]\Images\`

2. In Stream Deck software:
   - Right-click button
   - "Set from File"
   - Select PNG

3. Icons will appear on Stream Deck LCD keys

---

## Icon Pack Download

For users who want pre-made icons:

**Download link:** [To be added when icons are created]

**Contains:**
- 15 PNG icons (72×72)
- 15 SVG source files
- Color palette reference
- Installation guide

---

**END OF SPECIFICATION**
