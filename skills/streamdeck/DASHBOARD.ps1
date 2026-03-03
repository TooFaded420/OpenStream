# OpenClaw Stream Deck - Project Dashboard Launcher
# Opens an intuitive file browser view

$ProjectRoot = "$env:USERPROFILE\.openclaw\workspace\skills\streamdeck"

function Show-ProjectDashboard {
    Clear-Host
    
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║     OpenClaw Stream Deck Plugin - Project Dashboard         ║" -ForegroundColor Cyan
    Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "📊 PROJECT OVERVIEW" -ForegroundColor Yellow
    Write-Host "─────────────────────────────────────────────────────────────" -ForegroundColor DarkGray
    Write-Host ""
    
    # Quick stats
    $fileCount = (Get-ChildItem $ProjectRoot -Recurse -File).Count
    $folderCount = (Get-ChildItem $ProjectRoot -Recurse -Directory).Count
    $codeFiles = (Get-ChildItem "$ProjectRoot\*" -Include "*.ps1", "*.json" -Recurse).Count
    $docFiles = (Get-ChildItem "$ProjectRoot\*" -Include "*.md" -Recurse).Count
    
    Write-Host "  📁 Total Files:      $fileCount" -ForegroundColor White
    Write-Host "  📂 Total Folders:    $folderCount" -ForegroundColor White
    Write-Host "  💻 Code Files:       $codeFiles" -ForegroundColor Green
    Write-Host "  📄 Documentation:    $docFiles" -ForegroundColor Blue
    Write-Host ""
    
    # Main sections
    $sections = @(
        @{ Name = "🎮 PLUGIN (Latest)"; Path = "$ProjectRoot\plugin-v3"; Desc = "Main plugin v3.0" }
        @{ Name = "🔧 SCRIPTS"; Path = "$ProjectRoot\scripts"; Desc = "Automation scripts" }
        @{ Name = "🎨 ASSETS"; Path = "$ProjectRoot\assets"; Desc = "Icons & images" }
        @{ Name = "🏠 HOME ASSISTANT"; Path = "$ProjectRoot\home-assistant-addon"; Desc = "HA addon" }
        @{ Name = "📄 DOCUMENTATION"; Path = "$ProjectRoot"; Filter = "*.md"; Desc = "All docs" }
        @{ Name = "💰 MARKETING"; Path = "$ProjectRoot\marketing"; Desc = "Store & social" }
        @{ Name = "💡 FEATURES"; Path = "$ProjectRoot\features"; Desc = "Ideas & plans" }
    )
    
    Write-Host "📂 QUICK ACCESS" -ForegroundColor Yellow
    Write-Host "─────────────────────────────────────────────────────────────" -ForegroundColor DarkGray
    Write-Host ""
    
    for ($i = 0; $i -lt $sections.Count; $i++) {
        $section = $sections[$i]
        $num = $i + 1
        Write-Host "  [$num] $($section.Name)" -ForegroundColor Cyan -NoNewline
        Write-Host " - $($section.Desc)" -ForegroundColor DarkGray
    }
    
    Write-Host ""
    Write-Host "🚀 QUICK ACTIONS" -ForegroundColor Yellow
    Write-Host "─────────────────────────────────────────────────────────────" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  [V] Open in VS Code" -ForegroundColor Magenta
    Write-Host "  [E] Open in Explorer" -ForegroundColor Magenta
    Write-Host "  [I] View INDEX.md" -ForegroundColor Magenta
    Write-Host "  [R] Read README.md" -ForegroundColor Magenta
    Write-Host "  [Z] Create Release ZIP" -ForegroundColor Magenta
    Write-Host "  [Q] Quit" -ForegroundColor Red
    Write-Host ""
    
    $choice = Read-Host "Enter choice (1-7, V, E, I, R, Z, Q)"
    
    switch ($choice) {
        "1" { Open-Folder $sections[0].Path }
        "2" { Open-Folder $sections[1].Path }
        "3" { Open-Folder $sections[2].Path }
        "4" { Open-Folder $sections[3].Path }
        "5" { Open-Folder $sections[4].Path }
        "6" { Open-Folder $sections[5].Path }
        "7" { Open-Folder $sections[6].Path }
        "V" { Open-VSCode }
        "E" { Open-Explorer }
        "I" { Open-Index }
        "R" { Open-Readme }
        "Z" { Create-ReleaseZip }
        "Q" { return }
        default { 
            Write-Host "Invalid choice!" -ForegroundColor Red
            Start-Sleep 1
            Show-ProjectDashboard
        }
    }
}

function Open-Folder {
    param([string]$Path)
    if (Test-Path $Path) {
        explorer $Path
        Write-Host "✅ Opened: $Path" -ForegroundColor Green
    } else {
        Write-Host "❌ Folder not found: $Path" -ForegroundColor Red
    }
    Pause
    Show-ProjectDashboard
}

function Open-VSCode {
    code $ProjectRoot
    Write-Host "✅ Opened in VS Code" -ForegroundColor Green
    Pause
    Show-ProjectDashboard
}

function Open-Explorer {
    explorer $ProjectRoot
    Write-Host "✅ Opened in File Explorer" -ForegroundColor Green
    Pause
    Show-ProjectDashboard
}

function Open-Index {
    if (Test-Path "$ProjectRoot\INDEX.md") {
        Start-Process "$ProjectRoot\INDEX.md"
        Write-Host "✅ Opened INDEX.md" -ForegroundColor Green
    } else {
        Write-Host "❌ INDEX.md not found" -ForegroundColor Red
    }
    Pause
    Show-ProjectDashboard
}

function Open-Readme {
    if (Test-Path "$ProjectRoot\README.md") {
        Start-Process "$ProjectRoot\README.md"
        Write-Host "✅ Opened README.md" -ForegroundColor Green
    } else {
        Write-Host "❌ README.md not found" -ForegroundColor Red
    }
    Pause
    Show-ProjectDashboard
}

function Create-ReleaseZip {
    $version = "v3.0"
    $zipName = "OpenClaw-StreamDeck-$version.zip"
    $dest = "$env:USERPROFILE\Desktop\$zipName"
    
    Write-Host "📦 Creating release package..." -ForegroundColor Cyan
    
    # Create temp directory
    $tempDir = "$env:TEMP\openclaw-release"
    if (Test-Path $tempDir) { Remove-Item $tempDir -Recurse -Force }
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
    
    # Copy files
    Copy-Item "$ProjectRoot\plugin-v3\*" $tempDir -Recurse -Force
    Copy-Item "$ProjectRoot\README.md" $tempDir -Force
    Copy-Item "$ProjectRoot\LICENSE" $tempDir -Force
    
    # Create zip
    Compress-Archive -Path "$tempDir\*" -DestinationPath $dest -Force
    
    # Cleanup
    Remove-Item $tempDir -Recurse -Force
    
    Write-Host "✅ Created: $dest" -ForegroundColor Green
    Write-Host "📦 Size: $([math]::Round((Get-ChildItem $dest).Length/1KB, 1)) KB" -ForegroundColor Cyan
    
    Pause
    Show-ProjectDashboard
}

# Start
Show-ProjectDashboard