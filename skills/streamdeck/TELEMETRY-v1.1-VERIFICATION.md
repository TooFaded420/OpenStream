# Cost/Latency Telemetry Strip v1.1 - Verification Steps

## Files Modified
- `plugin-v5-sdk/app.js` - Telemetry tracking model and persistence
- `web-dashboard/host-server.ps1` - Telemetry API endpoints
- `web-dashboard/index.html` - Telemetry strip UI and auto-refresh

## Features Implemented

### 1. Telemetry Model (app.js)
- Tracks action latency, status codes, and results
- Persists to `~/.openclaw/telemetry.json` (max 100 events)
- Exports summary to `~/.openclaw/telemetry-export.json` for dashboard
- Records: timestamp, action name, result (ok/err), latencyMs, statusCode, gateway

### 2. API Endpoints (host-server.ps1)
- `GET /api/telemetry` - Returns summary (success rate, avg/min/max latency, status codes, recent errors)
- `GET /api/telemetry/events` - Returns last 20 events
- `POST /api/telemetry/clear` - Clears telemetry data

### 3. Dashboard Telemetry Strip (index.html)
- 6-card grid showing:
  - **Success Rate**: Percentage of successful calls (alerts if <90%)
  - **Avg Latency**: Average response time (alerts if >500ms)
  - **Min Latency**: Best-case response time
  - **Max Latency**: Worst-case response time (alerts if >1000ms)
  - **Status Codes**: Breakdown of OK, AUTH, TIME, OFF, ERR codes
  - **Recent Errors**: Count of errors in last 5 minutes
- Auto-refreshes every 5 seconds
- Color-coded warnings (green/normal, yellow/dim, red/alert)

## Verification Steps

### Step 1: Start the Dashboard Server
```powershell
cd C:\Users\jrlop\.openclaw\workspace\skills\streamdeck\web-dashboard
.\START-SERVER.bat 8787
```
Expected: "OpenClaw Dashboard server running on http://localhost:8787"

### Step 2: Test Telemetry API
```powershell
# Test telemetry summary endpoint
Invoke-RestMethod -Uri "http://localhost:8787/api/telemetry" -Method GET

# Test events endpoint  
Invoke-RestMethod -Uri "http://localhost:8787/api/telemetry/events" -Method GET

# Test clear endpoint
Invoke-RestMethod -Uri "http://localhost:8787/api/telemetry/clear" -Method POST
```

### Step 3: Verify Dashboard Rendering
1. Open browser to `http://localhost:8787`
2. Look for telemetry strip below the top panel (6 cards in a row)
3. Cards should show:
   - "No data" initially (or real data if plugin has been running)
   - Color-coded values based on thresholds

### Step 4: Test Telemetry Tracking
1. Start the Stream Deck plugin (v5-sdk)
2. Press any button (e.g., Status, TTS, Spawn)
3. Check telemetry updates in dashboard
4. Verify `~/.openclaw/telemetry.json` is created and contains events

### Step 5: Verify Persistence
1. Stop and restart the dashboard server
2. Telemetry data should persist (loaded from file)
3. Dashboard should display previously recorded events

## Expected Behavior

### Color Coding
- **Success Rate <90%**: Red warning
- **Success Rate <95%**: Yellow warning
- **Avg Latency >500ms**: Red warning
- **Avg Latency >200ms**: Yellow warning
- **Max Latency >1000ms**: Red warning on card border
- **Recent Errors >0**: Red error card

### Auto-Refresh
- Dashboard refreshes telemetry every 5 seconds
- Plugin exports telemetry every 10 seconds + on each action
- No page reload required to see updates

## Troubleshooting

### No telemetry data showing
- Ensure plugin-v5-sdk is running and making API calls
- Check browser console for JavaScript errors
- Verify `~/.openclaw/telemetry-export.json` exists

### High latency warnings
- Check gateway health: `http://127.0.0.1:18790/status`
- Verify network connectivity to gateway
- Consider enabling local gateway if using remote

### Persistence not working
- Ensure `~/.openclaw/` directory exists and is writable
- Check PowerShell has permission to write to user profile
- Verify JSON files are not corrupted

## Rollback
To revert changes:
```bash
git revert f762a65
```

Or manually restore from backup:
```bash
git checkout HEAD~1 -- plugin-v5-sdk/app.js web-dashboard/host-server.ps1 web-dashboard/index.html
```