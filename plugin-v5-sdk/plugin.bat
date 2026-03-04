@echo off
setlocal
set SCRIPT_DIR=%~dp0
set LOG=%TEMP%\openclaw-v5-launch.log
echo [%date% %time%] args: %*>> "%LOG%"
set NODE_EXE=%ProgramFiles%\nodejs\node.exe
if exist "%NODE_EXE%" (
  "%NODE_EXE%" "%SCRIPT_DIR%app.js" %* >> "%TEMP%\openclaw-v5-runtime.log" 2>&1
) else (
  node "%SCRIPT_DIR%app.js" %* >> "%TEMP%\openclaw-v5-runtime.log" 2>&1
)
echo [%date% %time%] exit: %errorlevel%>> "%LOG%"
exit /b %errorlevel%
