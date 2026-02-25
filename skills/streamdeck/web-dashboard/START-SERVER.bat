@echo off
setlocal
set PORT=%1
if "%PORT%"=="" set PORT=8787

echo ===================================
echo OpenClaw Dashboard Server
echo ===================================
echo.
echo Starting server on port %PORT%...
echo.
echo ACCESS:
echo http://localhost:%PORT%
echo.
echo (Phone must be on same WiFi)
echo.
echo Press Ctrl+C to stop
echo ===================================
cd /d "%~dp0"
python -m http.server %PORT%
pause
