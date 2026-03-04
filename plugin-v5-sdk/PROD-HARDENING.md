# Production Hardening Notes (v5 SDK)

This module now includes runtime safeguards aimed at production reliability.

## Runtime Guarantees

- Gateway calls reject invalid gateway config or absolute URL path input.
- Relative gateway paths are normalized (for example `status` -> `/status`).
- Retries are bounded with capped exponential backoff.
- Final retry attempts do not incur an unnecessary extra sleep.
- `failover_set` routing now falls back to active gateway if all failover targets are unhealthy.
- Settings updates from property inspector save gateway config once per event (atomic write path).
- Empty gateway token input clears token (`null`) instead of leaving stale credentials.
- Gateway/node poll timeout handles always clear timers (including error paths).
- WebSocket event processing is wrapped in a top-level handler `try/catch` to avoid loop crashes.

## Verification Commands

Run from `C:\Users\jrlop\.openclaw\workspace\skills\streamdeck`:

```powershell
node --check plugin-v5-sdk/app.js
npm run test:plugin
npm run build
```

## Follow-Up Recommendations

- Add integration tests for `app.js` settings flow by extracting the settings-apply logic into a testable module.
- Add a smoke test for `didReceiveSettings` token clear + route role updates.
- Add CI artifact upload for `telemetry-export.json` snapshots on test failures.
