# GitHub Release Readiness (v5.4.0)

Last updated: 2026-03-03

## Status

- Release target: `v5.4.0`
- Plugin manifest version: `5.4.0`
- Build gate: `npm run build` must pass before publishing
- Packaging command:

```powershell
.\scripts\package-v5-release.ps1 -Version 5.4.0
```

Artifacts produced:

- `dist/openclaw-streamdeck-v5-5.4.0.zip`
- `dist/openclaw-streamdeck-v5-5.4.0.zip.sha256.txt`

## Gateway and Routing Implications

The Stream Deck plugin routes each action to a configured gateway key from:

- `%USERPROFILE%\.openclaw\streamdeck-gateways.json`

Routing supports:

- `global_active`
- `fixed_gateway`
- `failover_set`
- `latency_best`
- `role_based`

Role-based mapping:

- `spawn`, `agents`, `subagents` -> `agents`
- `session`, `model` -> `session`
- `search`, `websearch` -> `research`
- `tts`, `audio` -> `audio`
- `nodes` -> `nodes`
- other actions -> `default`

## Using a Gateway on Another Computer

1. Add a new gateway entry in `streamdeck-gateways.json` with remote URL and token.
2. Ensure remote host is reachable from this machine.
3. Choose one of:
   - set it as `active` for all keys
   - set per-key `fixed_gateway` in property inspector
   - use `role_based` and map only selected roles to remote
4. For `Spawn` and `Search`, optionally set per-key `sessionKey` in property inspector.

Operational implications:

- Sessions are gateway-local. `agent:main:main` on remote is not the same session state as local.
- TTS state is gateway-local and will toggle on the selected target gateway.
- Health/Nodes results reflect the selected gateway.

## Known Operational Caveat

- Setup Wizard token sync currently copies token from `%USERPROFILE%\.openclaw\openclaw.json` to configured gateways.
- If local and remote gateways use different tokens, opening Setup Wizard can overwrite remote token values.
- Recommended: re-open key settings and set gateway token explicitly after setup when mixing local + remote gateways.
