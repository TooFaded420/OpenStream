# Example Button Layouts

Real-world configurations for different use cases.

## 💻 Developer Setup (MK.2 - 15 keys)

**Workflow:** Coding, debugging, code review

```
┌─────────┬─────────┬─────────┬─────────┬─────────┐
│  TTS    │  Spawn  │ Status  │ Models  │ Agents  │
│  Toggle │  Agent  │  Check  │  List   │  List   │
├─────────┼─────────┼─────────┼─────────┼─────────┤
│  Code   │  Debug  │ Memory  │ Web     │ Session │
│  Review │  Help   │ Search  │ Search  │  Info   │
├─────────┼─────────┼─────────┼─────────┼─────────┤
│  Node   │ Restart │ Config  │  Git    │ Browser │
│  Status │ Gateway │  View   │ Status  │  Open   │
└─────────┴─────────┴─────────┴─────────┴─────────┘
```

**Button Details:**
| Key | Action | Settings |
|-----|--------|----------|
| 1 | TTS Toggle | `endpoint: "/tts.toggle"` |
| 2 | Spawn Agent | `endpoint: "/spawn", body: {"task":"Quick task"}` |
| 3 | Status Check | `endpoint: "/status"` |
| 4 | List Models | `endpoint: "/models"` |
| 5 | Subagents | `endpoint: "/subagents.list"` |
| 6 | Code Review | `endpoint: "/spawn", body: {"task":"Review code"}` |
| 7 | Debug Help | `endpoint: "/spawn", body: {"task":"Debug this"}` |
| 8 | Memory Search | `endpoint: "/memory_search"` |
| 9 | Web Search | `endpoint: "/web.search"` |
| 10 | Session | `endpoint: "/session.status"` |
| 11 | Nodes | `endpoint: "/nodes.status"` |
| 12 | Restart | `endpoint: "/gateway.restart"` |
| 13 | Config | `endpoint: "/config.get"` |
| 14 | Git Status | `endpoint: "/spawn", body: {"task":"Check git status"}` |
| 15 | Browser | `endpoint: "/browser.open"` |

---

## 🎨 Content Creator (Stream Deck +)

**Workflow:** Recording, streaming, quick edits

**Keys (15):**
```
┌─────────┬─────────┬─────────┬─────────┬─────────┐
│  TTS    │  Quick  │ Memory  │  Web    │ Session │
│  Toggle │  Msg    │ Search  │ Search  │  Info   │
├─────────┼─────────┼─────────┼─────────┼─────────┤
│  Spawn  │ Models  │ Status  │ Nodes   │ Restart │
│  Agent  │ Switch  │  Check  │  Cam    │ Gateway │
├─────────┼─────────┼─────────┼─────────┼─────────┤
│  Code   │ Subag.  │ Config  │ Msg     │ Browser │
│ Helper  │  Kill   │  View   │ Broadcast│ Open   │
└─────────┴─────────┴─────────┴─────────┴─────────┘
```

**Dials (4):**
| Dial | Function | Press Action |
|------|----------|--------------|
| 1 | System Volume | Mute toggle |
| 2 | Mic Volume | Push to talk |
| 3 | Brightness | Reset to default |
| 4 | Scroll | Jump to top |

---

## 🤖 AI Power User (XL - 32 keys)

**Workflow:** Managing multiple agents, model switching, monitoring

**Layout:**
```
┌────┬────┬────┬────┬────┬────┬────┬────┐
│ TTS│Spawn│Stat│Mods│Subs│Node│Rest│Conf│ ← Quick actions
├────┼────┼────┼────┼────┼────┼────┼────┤
│ A1 │ A2 │ A3 │ A4 │ A5 │ A6 │ A7 │ A8 │ ← Agent slots
├────┼────┼────┼────┼────┼────┼────┼────┤
│ M1 │ M2 │ M3 │ M4 │ M5 │ M6 │ M7 │ M8 │ ← Model shortcuts
├────┼────┼────┼────┼────┼────┼────┼────┤
│Mem │Web │Ses │Cod │Git │Msg │Brw │Tool│ ← Tools
└────┴────┴────┴────┴────┴────┴────┴────┘
```

**Agent Slots (A1-A8):** Quick spawn of different agent types
```json
{
  "A1": {"task": "Code review", "agentId": "coding"},
  "A2": {"task": "Debug help", "agentId": "debug"},
  "A3": {"task": "Architecture", "agentId": "architect"},
  "A4": {"task": "Documentation", "agentId": "writer"}
}
```

**Model Shortcuts (M1-M8):** Instant model switching
```json
{
  "M1": "synthetic/hf:MiniMaxAI/MiniMax-M2.1",
  "M2": "synthetic/hf:moonshotai/Kimi-K2.5",
  "M3": "synthetic/hf:deepseek-ai/DeepSeek-V3"
}
```

---

## 🏠 Smart Home Hub (Mini - 6 keys)

**Workflow:** Home Assistant + OpenClaw integration

```
┌─────────┬─────────┐
│  Home   │  Away   │
│  Mode   │  Mode   │
├─────────┼─────────┤
│  TTS    │  AI     │
│  Toggle │  Query  │
├─────────┼─────────┤
│  Lights │  Temp   │
│  Scene  │  Check  │
└─────────┴─────────┘
```

**Home/Away Mode:** Triggers HA automations + OpenClaw context
**AI Query:** Quick voice query to OpenClaw
**Lights Scene:** Changes lights + logs to memory
**Temp Check:** Reads sensors + spawns agent if needed

---

## 🎯 Minimal Setup (Any - 3 keys)

**For:** Stream Deck Pedal or minimalists

```
┌─────────┬─────────┬─────────┐
│  TTS    │  Spawn  │  Status │
│  Toggle │  Agent  │  Check  │
└─────────┴─────────┴─────────┘
```

**TTS Toggle:** Enable/disable voice
**Spawn Agent:** Quick agent for tasks
**Status Check:** System health at a glance

---

## 🎓 Beginner-Friendly (MK.2)

**Simplified layout for new users:**

```
┌─────────┬─────────┬─────────┬─────────┬─────────┐
│  🤖     │  📝     │  🔍     │  🧠     │  ⚡     │
│  HELP   │  NOTE   │ SEARCH  │ REMEMBER│ STATUS  │
├─────────┼─────────┼─────────┼─────────┼─────────┤
│  💬     │  🎤     │  🔄     │  🌐     │  🛠️     │
│  CHAT   │  SPEAK  │ RESTART │  BROWSE │ TOOLS   │
├─────────┼─────────┼─────────┼─────────┼─────────┤
│         │         │         │         │         │
│  EMPTY  │  EMPTY  │  EMPTY  │  EMPTY  │  EMPTY  │
│         │         │         │         │         │
└─────────┴─────────┴─────────┴─────────┴─────────┘
```

**Icons:** Visual + text for clarity
**Actions:** Most common/useful only
**Empty slots:** Room to grow

---

## Importing These Layouts

1. **Generate profile:**
   ```powershell
   .\generate-profiles.ps1 -Template "developer"
   ```

2. **Import to Stream Deck:**
   - Open Stream Deck software
   - Profile dropdown → Import
   - Select generated `.sdProfile`

3. **Customize:**
   - Drag to rearrange
   - Right-click → Set Icon for visuals
   - Edit settings for your needs

---

## Creating Your Own

**Template:**
```powershell
$MyLayout = @{
    Name = "My-Custom-Layout"
    Actions = @(
        @{ Key = 0; Action = "com.openclaw.webhooks.action"; Settings = @{ endpoint = "/your-endpoint" }; Title = "My Button" }
        # ... more buttons
    )
}
```

**Save and import:**
```powershell
$MyLayout | ConvertTo-Json | Out-File "my-layout.json"
# Then import to Stream Deck
```