# Multi-Deck Framework v1

## Objective
Coordinate multiple Stream Deck devices on one computer using role-based profiles and a single OpenClaw SDK plugin (`com.openclaw.streamdeck.v5`).

## Roles
- `control` (MK.2/Mini): core action keys
- `dial` (Plus): dial-first controls + core keys
- `ops` (XL): monitoring + orchestration wall

## Pipeline
1. Detect connected devices
2. Install/verify plugin v5
3. Generate/verify role profiles
4. Auto-assign profiles to devices by serial/model
5. Run smoke test

## Files
- `scripts/detect-devices-v1.ps1`
- `scripts/auto-assign-profiles-v1.ps1`
- `scripts/test-multi-device-v1.ps1`
- `.openclaw/streamdeck-device-map.json` (persisted role map)

## Mapping defaults
- `type 7` (Stream Deck +) => `dial`
- `type 0|1` (MK.2/Mini) => `control`
- `type 2` (XL) => `ops`

## Notes
- Keep plugin runtime unified on v5.
- Avoid legacy `com.openclaw.webhooks` path for new installs.
- Profiles should be importable and role-stable per serial.
