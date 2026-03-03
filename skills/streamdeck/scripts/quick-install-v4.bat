@echo off
:: Quick install OpenClaw Live v4

echo Installing OpenClaw Live v4 (Chowder Integration)...
powershell.exe -ExecutionPolicy Bypass -File "%USERPROFILE%\.openclaw\workspace\skills\streamdeck\scripts\install-v4.ps1"

if %ERRORLEVEL% NEQ 0 (
    echo Installation failed!
    pause
    exit /b 1
)

echo.
echo Restarting Stream Deck...
taskkill /f /im "StreamDeck.exe" 2>nul
timeout /t 2 >nul
start "" "C:\Program Files\Elgato\StreamDeck\StreamDeck.exe"

echo.
echo Done! Stream Deck will open shortly.
pause
