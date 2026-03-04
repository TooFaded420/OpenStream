@echo off
:: Add Mission to Queue - Stream Deck Action Wrapper
:: Usage: add-mission.bat "Mission Title" "[Description]" "[priority:low/normal/high]"

set "TITLE=%~1"
set "DESC=%~2"
set "PRIORITY=%~3"

if "%TITLE%"=="" (
    echo ERROR: Mission title required
    exit /b 1
)

if "%DESC%"=="" set "DESC="
if "%PRIORITY%"=="" set "PRIORITY=normal"

powershell.exe -ExecutionPolicy Bypass -Command "& '%~dp0add-mission.ps1' -Title '%TITLE%' -Description '%DESC%' -Priority '%PRIORITY%'"
