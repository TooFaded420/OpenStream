# Pre-Commit Checklist

Run this checklist for every code change in this repository.

## Build and Tests

- [ ] Run `npm run build` from repo root and confirm it passes.
- [ ] If relevant, run targeted tests for changed areas and confirm they pass.

## Quality and Compatibility

- [ ] Confirm no syntax errors or partial edits remain.
- [ ] Confirm no ES target-incompatible APIs were introduced (for example, avoid `replaceAll` unless target support is verified).
- [ ] Confirm config and JSON serialization remain valid UTF-8 text.

## Stream Deck Plugin Safety

- [ ] Validate `plugin-v5-sdk/manifest.json` changes are intentional and UUIDs/controllers are correct.
- [ ] Validate property inspector changes still save/reload settings.
- [ ] Validate install flow (`scripts/install-v5-sdk.ps1`) still installs and restarts Stream Deck cleanly.

## Docs and Follow-Ups

- [ ] Add or update user-facing docs for any new setup/testing behavior.
- [ ] Document any temporary unsafe workaround with a clear `TODO`.
