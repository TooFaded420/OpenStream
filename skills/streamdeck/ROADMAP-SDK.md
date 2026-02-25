# OpenClaw Stream Deck SDK Plan (v5)

## Goal
Ship a **native, stable Stream Deck plugin runtime** (SDK-compliant) with strong UX and extensible OpenClaw actions.

## Phase 1 — Foundation (Now)
1. Create `plugin-v5-sdk/` with SDK-compliant runtime process
2. Parse required Stream Deck launch args (`-port`, `-pluginUUID`, `-registerEvent`, `-info`)
3. Open websocket, send registration event, maintain heartbeat/logging
4. Implement routing for `keyDown`, `keyUp`, `willAppear`, `didReceiveSettings`
5. Add OpenClaw HTTP client wrapper with timeout/retry and typed action handlers

## Phase 2 — Core Actions
1. Status check (`/status`)
2. TTS toggle (`config get/set`)
3. Spawn sub-agent (`/spawn`)
4. Session info (`/session.status`)
5. Subagents count (`/subagents.list`)

## Phase 3 — UX Polish
1. Per-action settings inspector (gateway URL, timeout, labels)
2. Better button states (idle/running/success/error)
3. Compact action-level telemetry in plugin logs
4. User-facing friendly errors (offline, timeout, auth)
5. Reconnect + offline fallback behavior

## Phase 4 — Power Features
1. Multi-gateway profiles/switching
2. Quick macros (multi-action sequences)
3. Optional local cache for recent status
4. Action templates for MK2/XL/Plus layouts
5. Optional voice workflow trigger actions

## Quality Gates
- Plugin loads without SDK conflict warnings
- No crash/restart loop in Stream Deck logs
- First 3 actions complete end-to-end on hardware
- Settings survive restarts
- Graceful handling when OpenClaw gateway unavailable

## Deliverables
- `skills/streamdeck/plugin-v5-sdk/` (runtime + manifest + inspector)
- Updated install script for v5
- Test checklist and known issues
