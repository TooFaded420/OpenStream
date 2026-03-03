@echo off
setlocal enabledelayedexpansion

:: OpenClaw Live Activity Plugin Launcher
:: Usage: openclaw-live-activity.bat <Action> <SettingsJSON> <Context>

set "SCRIPT_DIR=%~dp0"
set "ACTION=%~1"
set "SETTINGS=%~2"
set "CONTEXT=%~3"

if "%ACTION%"=="" set "ACTION=status"
if "%SETTINGS%"=="" set "SETTINGS={}"
if "%CONTEXT%"=="" set "CONTEXT=default"

:: PowerShell execution with error handling
powershell.exe -ExecutionPolicy Bypass -Command "& '%SCRIPT_DIR%openclaw-live-activity.ps1' -Action '%ACTION%' -Settings '%SETTINGS%' -Context '%CONTEXT%'"

exit /b %ERRORLEVEL%
