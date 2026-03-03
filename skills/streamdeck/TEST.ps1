# OpenClaw Stream Deck - Quick Test
# Verifies installation and tests buttons

param([switch]$Verbose)

Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   OpenClaw Stream Deck - Installation Test             ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

$Tests = @()
$Passed = 0
$Failed = 0

function Test-Step {
    param($Name, $Script)
    Write-Host "Testing: $Name..." -NoNewline
    try {
        & $Script
        Write-Host " ✓ PASSED" -ForegroundColor Green
        $script:Passed++
        return $true
    } catch {
        Write-Host " ✗ FAILED: $_" -ForegroundColor Red
        $script:Failed++
        return $false
    }
}

# Test 1: Stream Deck software
Test-Step "Stream Deck Software" {
    $paths = @(
        "$env:ProgramFiles\Elgato\StreamDeck\StreamDeck.exe",
        "$env:LOCALAPPDATA\Programs\Elgato\StreamDeck\StreamDeck.exe"
    )
    $found = $paths | Where-Object { Test-Path $_ } | Select-Object -First 1
    if (-not $found) { throw "Stream Deck not found" }
}

# Test 2: Plugin installed
Test-Step "OpenClaw Plugin" {
    $plugin = "$env:APPDATA\Elgato\StreamDeck\Plugins\com.openclaw.webhooks.sdPlugin"
    if (-not (Test-Path $plugin)) { throw "Plugin not installed" }
}

# Test 3: Gateway running
Test-Step "OpenClaw Gateway" {
    try {
        $response = Invoke-RestMethod -Uri "http://127.0.0.1:18790/status" -Method Get -TimeoutSec 3
    } catch {
        throw "Gateway not responding"
    }
}

# Test 4: Profiles exist
Test-Step "Generated Profiles" {
    $profiles = "$env:APPDATA\Elgato\StreamDeck\ProfilesV2\OpenClaw*"
    if (-not (Test-Path $profiles)) { throw "No OpenClaw profiles found" }
}

# Test 5: Config file
Test-Step "Configuration File" {
    $config = "$env:USERPROFILE\.openclaw\streamdeck-plugin\config.ps1"
    if (-not (Test-Path $config)) { throw "Config not found" }
}

# Summary
Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "Test Results: $Passed passed, $Failed failed" -ForegroundColor $(if ($Failed -eq 0) { "Green" } else { "Yellow" })
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan

if ($Failed -eq 0) {
    Write-Host ""
    Write-Host "🎉 All tests passed! Your Stream Deck is ready to use." -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:"
    Write-Host "  1. Open Stream Deck software"
    Write-Host "  2. Look for 'OpenClaw' profiles"
    Write-Host "  3. Drag actions to buttons"
    Write-Host "  4. Start using OpenClaw from your Stream Deck!"
} else {
    Write-Host ""
    Write-Host "⚠ Some tests failed. Run ONBOARDING.ps1 to fix." -ForegroundColor Yellow
}

Write-Host ""
Read-Host "Press Enter to exit"