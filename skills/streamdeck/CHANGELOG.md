# Changelog

## v5.4.0 (2026-03-03)

### Added

- GitHub release readiness guide with gateway routing/remote gateway implications:
  - `docs/GITHUB_RELEASE_READINESS.md`
- Property inspector settings for operational action targeting:
  - `sessionKey`, `spawnTask`, `searchQuery`, `searchCount`

### Changed

- Stream Deck plugin runtime now uses visual action feedback:
  - success overlay (`showOk`)
  - error overlay (`showAlert`)
- `TTS` key and dial press now call gateway methods:
  - `tts.enable`
  - `tts.disable`
- `Spawn` and `Search` now send actionable gateway requests with explicit session targeting and delivery intent.
- Gateway RPC compatibility mapping expanded for:
  - `/web.search`
  - `/tts.enable`
  - `/tts.disable`

### Validation

- `npm run build` passes (web-dashboard tests + plugin tests)
