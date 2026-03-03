@echo off
powershell -ExecutionPolicy Bypass -File "%~dp0openclaw-plugin.ps1" -Action %1 -Settings %2
