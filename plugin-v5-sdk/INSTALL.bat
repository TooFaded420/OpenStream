@echo off
REM Quick install script for OpenClaw SDK v5 with Dial Pack
REM Run from plugin-v5-sdk folder

echo Installing OpenClaw SDK v5 with Dial Pack...
set SRC=%~dp0
set DST=%APPDATA%\Elgato\StreamDeck\Plugins\com.openclaw.streamdeck.v5.sdPlugin

if exist "%DST%" (
    echo Removing old installation...
    rmdir /s /q "%DST%"
)

echo Copying files...
xcopy /s /e /i "%SRC%" "%DST%"

echo.
echo Installation complete: %DST%
echo Restart Stream Deck software to load the plugin.
pause
