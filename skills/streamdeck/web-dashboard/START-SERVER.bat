@echo off
setlocal
set PORT=%1
if "%PORT%"=="" set PORT=8787

echo ===================================
echo OpenClaw Dashboard Server (Node)
echo ===================================
echo Starting on http://localhost:%PORT%
echo Press Ctrl+C to stop
cd /d "%~dp0"
node server.js %PORT%
pause
