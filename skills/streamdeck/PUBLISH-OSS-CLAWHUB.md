# Open Source + ClawHub Packaging Plan

This repo now has a production packaging path for the Stream Deck SDK v5 plugin.

Release readiness details are tracked in:

- `docs/GITHUB_RELEASE_READINESS.md`

## Artifacts

- Plugin runtime: `plugin-v5-sdk/`
- Dashboard + wizard: `web-dashboard/`
- Robust installer: `scripts/install-v5-sdk.ps1`
- Release packager: `scripts/package-v5-release.ps1`
- Stream Deck+ starter profile installer: `scripts/install-plus-starter-profile-v5.ps1`

## One-Command Local Install

```powershell
.\scripts\install-v5-sdk.ps1 -Force
.\scripts\install-plus-starter-profile-v5.ps1 -Overwrite
```

## Build + Test Gate

```powershell
npm run build
```

Runs dashboard contract tests and plugin routing/retry integration tests.

## Create Release Zip

```powershell
.\scripts\package-v5-release.ps1 -Version 5.4.0
```

Outputs:

- `dist/openclaw-streamdeck-v5-5.4.0.zip`
- `dist/openclaw-streamdeck-v5-5.4.0.zip.sha256.txt`

## GitHub Open Source Release

1. Tag release: `v5.4.0`
2. Run CI (`npm run build`)
3. Upload the zip + sha256 to GitHub release
4. Release notes should include:
   - New routing modes
   - Per-key routing inspector
   - Gateway health + node polling
   - Stream Deck+ starter profile

## ClawHub Readiness

If ClawHub supports zip-based package ingestion, publish the `dist/*.zip` artifact and reference:

- install command: `.\scripts\install-v5-sdk.ps1 -Force`
- optional profile bootstrap: `.\scripts\install-plus-starter-profile-v5.ps1 -Overwrite`

If ClawHub requires manifest metadata, map these fields:

- `name`: `openclaw-streamdeck-v5`
- `version`: release version (e.g. `5.4.0`)
- `platform`: `windows`
- `entrypoint`: `scripts/install-v5-sdk.ps1`
- `checksum`: SHA256 from `.sha256.txt`
