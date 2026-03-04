#!/usr/bin/env pwsh
# Install script for OpenClaw SDK v5 with Dial Pack
param([switch]$Force)
$ErrorActionPreference = 'Stop'

$src = Split-Path -Parent $MyInvocation.MyCommand.Path
$dst = "$env:APPDATA\Elgato\StreamDeck\Plugins\com.openclaw.streamdeck.v5.sdPlugin"

if (-not (Test-Path $src)) { throw "Source missing: $src" }
if ((Test-Path $dst) -and -not $Force) { 
    Write-Host "Already installed. Use -Force to reinstall."
    exit 0 
}
if (Test-Path $dst) { 
    Write-Host "Removing old installation..."
    Remove-Item -Recurse -Force $dst 
}

Write-Host "Installing to: $dst"
Copy-Item -Recurse $src $dst
Write-Host "Installation complete!"
Write-Host "Restart Stream Deck software to load the plugin."
