# OpenClaw Stream Deck v5 - Dial Pack v1 Guide

Complete guide for using OpenClaw Stream Deck v5 with Dial Pack v1 for Stream Deck Plus.

---

## Overview

**Dial Pack v1** extends OpenClaw v5 to support Stream Deck Plus dials (encoders) and touch strips. This enables physical dial control for volume, navigation, and OpenClaw-specific operations like session management and subagent scaling.

**Requirements:**
- Stream Deck Plus hardware
- Stream Deck software 6.0+
- OpenClaw v5.1.0+

---

## Setup

### 1. Install Plugin

1. Copy `plugin-v5-sdk` folder to your Stream Deck plugins directory:
   - **Windows:** `%APPDATA%\Elgato\StreamDeck\Plugins\`
   - **macOS:** `~/Library/Application Support/com.elgato.Elgato-Stream-Deck/Plugins/`

2. Restart Stream Deck software

3. Plugin appears under **"OpenClaw"** category

### 2. Configure Actions

Each dial action supports:
- **Controllers:** `Encoder` (dial + touch strip)
- **Keypad:** Standard button mode (fallback)

**Example manifest entry for dial-enabled action:**

```json
{
  "UUID": "com.openclaw.v5.dial.volume",
  "Name": "Volume Control",
  "Controllers": ["Encoder"],
  "Encoder": {
    "layout": "$B1",
    "TriggerDescription": {
      "Rotate": "Adjust volume",
      "Push": "Mute/unmute"
    }
  },
  "States": [{ "Image": "images/volume", "Title": "Vol" }]
}
```

### 3. Assign to Stream Deck Plus

1. Open Stream Deck software
2. Switch to your OpenClaw profile
3. Drag dial actions to encoder positions (top row of Stream Deck Plus)
4. Configure per-dial settings via Property Inspector

---

## Per-Dial Behavior

### Events Overview

| Event | Trigger | Use Case |
|-------|---------|----------|
| `dialRotate` | Dial turned | Increment/decrement values |
| `dialDown` | Dial pressed down | Start action, trigger menu |
| `dialUp` | Dial released | Complete action, execute command |
| `touchTap` | Touch strip tapped | Quick action, toggle |
| `touchLongPress` | Touch strip held | Secondary action |

### Dial Rotate Event

**Event:** `dialRotate`

**Payload:**
```json
{
  "event": "dialRotate",
  "action": "com.openclaw.v5.dial.volume",
  "context": "unique-instance-id",
  "device": "device-id",
  "payload": {
    "controller": "Encoder",
    "coordinates": { "column": 0, "row": 0 },
    "ticks": 5,      // positive = clockwise, negative = counter-clockwise
    "pressed": false // true if rotated while pressed
  }
}
```

**Per-Dial Behavior:**

| Direction | Expected Action |
|-----------|-----------------|
| **Clockwise (+ticks)** | Increase value (volume up, zoom in, next item) |
| **Counter-clockwise (-ticks)** | Decrease value (volume down, zoom out, previous item) |

**Implementation Example:**
```javascript
if (evt.event === 'dialRotate') {
  const ticks = evt.payload.ticks;
  const action = evt.action;
  
  if (action === 'com.openclaw.v5.dial.volume') {
    await adjustVolume(ticks * 2); // 2% per tick
  } else if (action === 'com.openclaw.v5.dial.zoom') {
    await adjustZoom(ticks);
  }
}
```

### Dial Press Events

**dialDown Event:**
```json
{
  "event": "dialDown",
  "action": "com.openclaw.v5.dial.volume",
  "context": "unique-instance-id",
  "payload": {
    "controller": "Encoder",
    "coordinates": { "column": 0, "row": 0 },
    "settings": { ... }
  }
}
```

**dialUp Event:**
```json
{
  "event": "dialUp",
  "action": "com.openclaw.v5.dial.volume",
  "context": "unique-instance-id",
  "payload": {
    "controller": "Encoder",
    "coordinates": { "column": 0, "row": 0 },
    "settings": { ... }
  }
}
```

**Per-Dial Behavior:**

| Action | Expected Result |
|--------|-----------------|
| **Press** | Trigger primary action (mute toggle, execute command) |
| **Press + Rotate** | Fine-grained adjustment (precision mode) |
| **Quick tap** | Immediate action |
| **Hold 1s+** | Enter secondary mode |

### Touch Strip Events

**touchTap Event:**
```json
{
  "event": "touchTap",
  "action": "com.openclaw.v5.dial.volume",
  "context": "unique-instance-id",
  "payload": {
    "controller": "Encoder",
    "coordinates": { "column": 0, "row": 0 },
    "tapPos": [50, 25] // [x, y] of tap on touch strip (200x100 px)
  }
}
```

**Per-Dial Behavior:**

| Gesture | Expected Action |
|---------|-----------------|
| **Tap left** | Previous preset |
| **Tap center** | Toggle mode |
| **Tap right** | Next preset |
| **Swipe** | Quick navigation |

---

## Expected Feedback

### Touch Strip Layouts

Built-in layouts (set via `setFeedbackLayout`):

| Layout | Description | Use Case |
|--------|-------------|----------|
| `$X1` | Icon only | Simple status indicators |
| `$A0` | Canvas (empty) | Custom drawing |
| `$A1` | Value display | Numeric feedback |
| `$B1` | Indicator | Progress bars |
| `$B2` | Gradient indicator | Range visualization |
| `$C1` | Double indicator | Dual-value display |

### setFeedback Payload

```javascript
// Update touch strip display
send({
  event: 'setFeedback',
  context: contextId,
  payload: {
    title: 'Volume',
    value: '75%',
    indicator: { value: 75, range: { min: 0, max: 100 } }
  }
});
```

### Visual Feedback Patterns

| State | Visual Indicator |
|-------|------------------|
| **Active/Ready** | Normal brightness, current value shown |
| **Processing** | Pulsing or "..." indicator |
| **Success** | Brief green highlight, checkmark |
| **Error** | Red tint, error icon |
| **Muted** | Slash through icon, dimmed |

### Haptic/Physical Feedback

- **Tick marks** on rotation (felt every N ticks)
- **Soft stop** at min/max values
- **Press confirmation** on dialDown

---

## Dial Actions Reference

### Included Dial Actions

| Action | Rotate (CW/CCW) | Press | Touch |
|--------|-----------------|-------|-------|
| **Volume** | +5% / -5% | Mute toggle | Tap for quick mute |
| **Zoom** | Zoom in/out | Reset 100% | Preset levels |
| **Scroll** | Page down/up | Jump to top | Position indicator |
| **Subagents** | Scale up/down | Spawn helper | List view |
| **TTS** | Rate +10% / -10% | Toggle ON/OFF | Voice select |
| **Brightness** | +10% / -10% | Auto-adjust | Preset modes |

### OpenClaw-Specific Dial Behaviors

**Subagents Dial:**
- CW: Spawn new subagent (up to limit)
- CCW: List oldest subagent
- Press: Quick-spawn default helper
- Touch: View active subagents

**Session Dial:**
- CW: Cycle model (GPT-4 → Claude → etc.)
- CCW: Toggle reasoning mode
- Press: Session status refresh
- Touch: Quick model info

**Nodes Dial:**
- CW: Next paired node
- CCW: Previous paired node
- Press: Ping/refresh nodes
- Touch: Node camera snapshot

---

## Quick-Start Layout Map

### Stream Deck Plus Layout

```
┌─────────────────────────────────────────────────────┐
│  [Dial 1]   [Dial 2]   [Dial 3]   [Dial 4]          │  ← 4 Touch Strips (200×100 px each)
│   Volume    Scroll    Subagents   Session          │
└─────────────────────────────────────────────────────┘
┌─────┬─────┬─────┬─────┬─────┬─────┬─────┬─────┐
│ TTS │ Srch│Spawn│Stus │Agnts│Nodes│Rcnct│ ??? │  ← 8 LCD Keys (72×72 px)
└─────┴─────┴─────┴─────┴─────┴─────┴─────┴─────┘
┌─────┬─────┬─────┬─────┬─────┬─────┬─────┬─────┐
│  1  │  2  │  3  │  4  │  5  │  6  │  7  │  8  │  ← 8 LCD Keys
└─────┴─────┴─────┴─────┴─────┴─────┴─────┴─────┘
┌─────┬─────┬─────┬─────┬─────┴─────┴─────┴─────┐
│  9  │  10 │  11 │  12 │                       │  ← 4 LCD Keys
└─────┴─────┴─────┴─────┴───────────────────────┘

DIAL PHYSICAL LAYOUT:
[ ◉ Dial 1 ] [ ◉ Dial 2 ] [ ◉ Dial 3 ] [ ◉ Dial 4 ]
   (press         (press         (press         (press
    + rotate)     + rotate)      + rotate)      + rotate)
```

### Default Profile Assignment

| Position | Type | Action | Quick Reference |
|----------|------|--------|-----------------|
| **Dial 1** | Encoder | Volume | ◉↻ = adjust, ◉↓ = mute |
| **Dial 2** | Encoder | Scroll | ◉↻ = page scroll, ◉↓ = top |
| **Dial 3** | Encoder | Subagents | ◉↻ = spawn/scale, ◉↓ = quick helper |
| **Dial 4** | Encoder | Session | ◉↻ = model cycle, ◉↓ = status |
| **Key 1** | Keypad | TTS | Toggle voice output |
| **Key 2** | Keypad | Search | Quick web search |
| **Key 3** | Keypad | Spawn | Spawn agent |
| **Key 4** | Keypad | Status | Gateway status |
| **Key 5** | Keypad | Agents | List subagents |
| **Key 6** | Keypad | Nodes | Paired nodes |
| **Key 7** | Keypad | Reconnect | Ping gateway |

---

## Troubleshooting

### Dial Not Responding

| Symptom | Cause | Solution |
|---------|-------|----------|
| No rotation events | Plugin not registered | Check WebSocket connection; restart plugin |
| No touch events | Layout not set | Call `setFeedbackLayout` on `willAppear` |
| Events firing but no action | Missing event handler | Verify `dialRotate`/`dialDown` handlers registered |
| Inconsistent tick counts | Sensitivity | Normalize tick values (divide by expected step) |

### Touch Strip Issues

| Symptom | Cause | Solution |
|---------|-------|----------|
| Blank screen | No layout assigned | Use `$A0` (canvas) minimum; set default layout in manifest |
| Layout not updating | Wrong context | Use encoder instance context, not action UUID |
| Text cut off | Layout too small | Use `$A1` or custom layout with proper rect sizing |

### Event Debugging

**Enable debug logging:**
```javascript
// In app.js, add before ws.addEventListener('message', ...)
ws.addEventListener('message', (event) => {
  console.log('[RAW]', event.data);
  // ... existing handler
});
```

**Common Event Payload Issues:**
- `controller` should be `"Encoder"` for dial actions
- `coordinates.column` is 0-3 for Stream Deck Plus (4 dials)
- `ticks` can be >1 for fast rotations; handle accumulation

### Performance

| Issue | Cause | Fix |
|-------|-------|-----|
| Laggy feedback | Too many setFeedback calls | Debounce to 60fps max (~16ms) |
| High CPU | Event spam | Filter small tick values (< 2) |
| Memory leak | Context not released | Handle `willDisappear` to cleanup |

### Gateway Connection

If dial actions don't respond:
1. Check gateway status: press "Status" key or visit `http://127.0.0.1:18790/status`
2. Verify `cfg.gateway` URL matches your OpenClaw instance
3. Check firewall rules for port 18790

---

## Code Reference

### Minimal Dial Handler Template

```javascript
// Handle all dial events
ws.addEventListener('message', async (event) => {
  let evt;
  try { evt = JSON.parse(String(event.data)); } catch { return; }

  const { context, action, payload } = evt;

  switch (evt.event) {
    case 'willAppear':
      if (payload?.controller === 'Encoder') {
        // Set default layout for touch strip
        send({ event: 'setFeedbackLayout', context, payload: { layout: '$B1' } });
      }
      break;

    case 'dialRotate':
      await handleDialRotate(context, action, payload.ticks, payload.pressed);
      break;

    case 'dialDown':
      await handleDialDown(context, action);
      break;

    case 'dialUp':
      await handleDialUp(context, action);
      break;

    case 'touchTap':
      await handleTouchTap(context, action, payload.tapPos);
      break;
  }
});

async function handleDialRotate(context, action, ticks, pressed) {
  const multiplier = pressed ? 0.5 : 1; // Precision mode when pressed
  const adjustedTicks = ticks * multiplier;
  
  // Update feedback
  send({
    event: 'setFeedback',
    context,
    payload: { value: `${adjustedTicks > 0 ? '+' : ''}${adjustedTicks}` }
  });
}
```

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| v1.0.0 | 2024-XX-XX | Initial Dial Pack release |
| v1.0.1 | TBD | Added `setTriggerDescription` support |

---

## Resources

- [Stream Deck SDK - Dials & Touch Strip](https://docs.elgato.com/streamdeck/sdk/guides/dials/)
- [Stream Deck SDK - Events Reference](https://docs.elgato.com/streamdeck/sdk/references/websocket/plugin/)
- [OpenClaw Gateway API](http://127.0.0.1:18790/docs)

---

*Dial Pack v1 - OpenClaw Stream Deck v5*
*Compatible with Stream Deck Plus, Stream Deck software 6.0+*