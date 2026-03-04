# OpenStream Stream Deck v5 Plugin

This repo contains only the OpenClaw Stream Deck v5 plugin runtime and installer.

## What is included

- `plugin-v5-sdk/` - Stream Deck v5 plugin files (manifest, runtime, icons, tests)
- `scripts/install-v5-sdk.ps1` - Windows installer/reinstaller for Stream Deck
- `package.json` - quality gates (`npm run build` runs plugin tests)

## Install on Windows

1. Close Stream Deck app.
2. Open PowerShell in this repo.
3. Run:

```powershell
.\scripts\install-v5-sdk.ps1 -Force -ClearCache
```

4. Launch Stream Deck.

## Gateway config

Installer writes/updates:

- `%USERPROFILE%\.openclaw\streamdeck-gateways.json`

Default gateway is:

- `http://127.0.0.1:18790`

## Validate

```bash
npm run build
```
