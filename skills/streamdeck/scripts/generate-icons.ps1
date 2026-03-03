# Generate Stream Deck Icons for OpenClaw
# Creates actual 72x72 PNG files with OpenClaw coral red (#ff5c5c)

Add-Type -AssemblyName System.Drawing

$IconDir = "$env:USERPROFILE\.openclaw\workspace\skills\streamdeck\assets\icons"
if (-not (Test-Path $IconDir)) {
    New-Item -ItemType Directory -Path $IconDir -Force | Out-Null
}

# Colors
$Coral = [System.Drawing.Color]::FromArgb(255, 92, 92)      # #ff5c5c
$White = [System.Drawing.Color]::FromArgb(255, 255, 255)      # #ffffff
$DarkBg = [System.Drawing.Color]::FromArgb(18, 20, 26)      # #12141a (approximate)

function New-IconCanvas {
    param([int]$Size = 72)
    $bmp = New-Object System.Drawing.Bitmap($Size, $Size)
    $bmp.MakeTransparent()
    return $bmp
}

function Save-Icon {
    param([System.Drawing.Bitmap]$Bitmap, [string]$Name)
    $path = Join-Path $IconDir "$Name.png"
    $Bitmap.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
    $Bitmap.Dispose()
    Write-Host "Created: $Name.png" -ForegroundColor Green
}

# Helper to draw rounded rectangle
function Draw-RoundedRect {
    param($Graphics, $Brush, $Rect, $Radius)
    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $path.AddArc($Rect.X, $Rect.Y, $Radius*2, $Radius*2, 180, 90)
    $path.AddArc($Rect.X + $Rect.Width - $Radius*2, $Rect.Y, $Radius*2, $Radius*2, 270, 90)
    $path.AddArc($Rect.X + $Rect.Width - $Radius*2, $Rect.Y + $Rect.Height - $Radius*2, $Radius*2, $Radius*2, 0, 90)
    $path.AddArc($Rect.X, $Rect.Y + $Rect.Height - $Radius*2, $Radius*2, $Radius*2, 90, 90)
    $path.CloseFigure()
    $Graphics.FillPath($Brush, $path)
}

Write-Host "Generating OpenClaw Stream Deck Icons..." -ForegroundColor Cyan
Write-Host "Icon size: 72x72 pixels"
Write-Host "Primary color: Coral Red (#ff5c5c)"
Write-Host ""

# 1. TTS Icon - Speaker with waves
$bmp = New-IconCanvas
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.Clear([System.Drawing.Color]::Transparent)

# Speaker cone
$speakerBrush = New-Object System.Drawing.SolidBrush($White)
$speakerPoints = @(
    [System.Drawing.Point]::new(18, 28),
    [System.Drawing.Point]::new(28, 28),
    [System.Drawing.Point]::new(38, 20),
    [System.Drawing.Point]::new(38, 52),
    [System.Drawing.Point]::new(28, 44),
    [System.Drawing.Point]::new(18, 44)
)
$g.FillPolygon($speakerBrush, $speakerPoints)

# Sound waves (coral)
$wavePen = New-Object System.Drawing.Pen($Coral, 3)
$wavePen.Cap = [System.Drawing.Drawing2D.LineCap]::Round
$g.DrawArc($wavePen, 42, 24, 14, 24, -60, 120)
$g.DrawArc($wavePen, 48, 20, 16, 32, -60, 120)

Save-Icon -Bitmap $bmp -Name "tts"
$g.Dispose()

# 2. Spawn Agent - Robot head with plus
$bmp = New-IconCanvas
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.Clear([System.Drawing.Color]::Transparent)

# Robot head (white outline)
$robotPen = New-Object System.Drawing.Pen($White, 3)
$robotPen.Cap = [System.Drawing.Drawing2D.LineCap]::Round
$g.DrawRoundedRectangle($robotPen, 20, 18, 32, 32, 6)

# Eyes
$eyeBrush = New-Object System.Drawing.SolidBrush($Coral)
$g.FillEllipse($eyeBrush, 26, 28, 6, 6)
$g.FillEllipse($eyeBrush, 40, 28, 6, 6)

# Plus sign in corner
$plusPen = New-Object System.Drawing.Pen($Coral, 3)
$g.DrawLine($plusPen, 52, 10, 52, 22)
$g.DrawLine($plusPen, 46, 16, 58, 16)

Save-Icon -Bitmap $bmp -Name "spawn"
$g.Dispose()

# 3. Status - Gauge
$bmp = New-IconCanvas
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.Clear([System.Drawing.Color]::Transparent)

# Gauge outline
$gaugePen = New-Object System.Drawing.Pen($White, 3)
$gaugePen.Cap = [System.Drawing.Drawing2D.LineCap]::Round
$g.DrawArc($gaugePen, 16, 20, 40, 40, 180, 180)

# Tick marks
$tickPen = New-Object System.Drawing.Pen($Coral, 2)
for ($i = 0; $i -le 4; $i++) {
    $angle = 180 + ($i * 45)
    $rad = $angle * [Math]::PI / 180
    $x1 = 36 + [Math]::Cos($rad) * 18
    $y1 = 40 + [Math]::Sin($rad) * 18
    $x2 = 36 + [Math]::Cos($rad) * 14
    $y2 = 40 + [Math]::Sin($rad) * 14
    $g.DrawLine($tickPen, $x1, $y1, $x2, $y2)
}

# Needle (coral)
$needlePen = New-Object System.Drawing.Pen($Coral, 3)
$needlePen.Cap = [System.Drawing.Drawing2D.LineCap]::Round
$rad = 225 * [Math]::PI / 180
$x = 36 + [Math]::Cos($rad) * 16
$y = 40 + [Math]::Sin($rad) * 16
$g.DrawLine($needlePen, 36, 40, $x, $y)

# Center dot
$g.FillEllipse($eyeBrush, 33, 37, 6, 6)

Save-Icon -Bitmap $bmp -Name "status"
$g.Dispose()

# 4. Models - Brain
$bmp = New-IconCanvas
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.Clear([System.Drawing.Color]::Transparent)

# Brain outline (white)
$brainPen = New-Object System.Drawing.Pen($White, 3)
$brainPen.Cap = [System.Drawing.Drawing2D.LineCap]::Round
$g.DrawEllipse($brainPen, 20, 16, 32, 28)

# Brain curves (coral)
$curvePen = New-Object System.Drawing.Pen($Coral, 2)
$g.DrawArc($curvePen, 26, 22, 20, 16, 180, 180)
$g.DrawArc($curvePen, 24, 26, 24, 16, 0, 180)

# Circuit nodes
$nodeBrush = New-Object System.Drawing.SolidBrush($Coral)
$g.FillEllipse($nodeBrush, 30, 30, 4, 4)
$g.FillEllipse($nodeBrush, 42, 30, 4, 4)
$g.FillEllipse($nodeBrush, 36, 38, 4, 4)

Save-Icon -Bitmap $bmp -Name "models"
$g.Dispose()

# 5. Subagents - Connected nodes
$bmp = New-IconCanvas
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.Clear([System.Drawing.Color]::Transparent)

# Connection lines (coral)
$linePen = New-Object System.Drawing.Pen($Coral, 2)
$g.DrawLine($linePen, 24, 36, 48, 36)
$g.DrawLine($linePen, 24, 36, 36, 24)
$g.DrawLine($linePen, 48, 36, 36, 48)

# Nodes (white with coral center)
$whiteBrush = New-Object System.Drawing.SolidBrush($White)
$coralBrush = New-Object System.Drawing.SolidBrush($Coral)
$g.FillEllipse($whiteBrush, 18, 30, 12, 12)
$g.FillEllipse($coralBrush, 21, 33, 6, 6)
$g.FillEllipse($whiteBrush, 42, 30, 12, 12)
$g.FillEllipse($coralBrush, 45, 33, 6, 6)
$g.FillEllipse($whiteBrush, 30, 18, 12, 12)
$g.FillEllipse($coralBrush, 33, 21, 6, 6)

Save-Icon -Bitmap $bmp -Name "subagents"
$g.Dispose()

# 6. Node Status - Antenna
$bmp = New-IconCanvas
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.Clear([System.Drawing.Color]::Transparent)

# Antenna base (white)
$baseRect = [System.Drawing.Rectangle]::new(30, 44, 12, 14)
$g.FillRectangle($whiteBrush, $baseRect)

# Antenna pole (white)
$polePen = New-Object System.Drawing.Pen($White, 3)
$g.DrawLine($polePen, 36, 44, 36, 20)

# Signal waves (coral)
$signalPen = New-Object System.Drawing.Pen($Coral, 2)
$g.DrawArc($signalPen, 32, 8, 8, 8, 180, 180)
$g.DrawArc($signalPen, 28, 4, 16, 12, 180, 180)
$g.DrawArc($signalPen, 24, 0, 24, 16, 180, 180)

Save-Icon -Bitmap $bmp -Name "nodes"
$g.Dispose()

# 7. Restart - Circular arrow
$bmp = New-IconCanvas
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.Clear([System.Drawing.Color]::Transparent)

# Circular arrow (coral)
$arrowPen = New-Object System.Drawing.Pen($Coral, 4)
$arrowPen.Cap = [System.Drawing.Drawing2D.LineCap]::Round
$g.DrawArc($arrowPen, 18, 18, 36, 36, 45, 270)

# Arrow head
$headPen = New-Object System.Drawing.Pen($Coral, 4)
$headPen.Cap = [System.Drawing.Drawing2D.LineCap]::Round
$headPen.EndCap = [System.Drawing.Drawing2D.LineCap]::ArrowAnchor
$rad = 45 * [Math]::PI / 180
$x = 36 + [Math]::Cos($rad) * 18
$y = 36 + [Math]::Sin($rad) * 18
$g.DrawLine($headPen, $x, $y, $x-8, $y+8)

Save-Icon -Bitmap $bmp -Name "restart"
$g.Dispose()

# 8. Config - Gear
$bmp = New-IconCanvas
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.Clear([System.Drawing.Color]::Transparent)

# Gear outline (white)
$gearPen = New-Object System.Drawing.Pen($White, 3)
$gearPen.Cap = [System.Drawing.Drawing2D.LineCap]::Round

# Draw gear with 8 teeth
for ($i = 0; $i -lt 8; $i++) {
    $angle = $i * 45
    $rad1 = ($angle - 15) * [Math]::PI / 180
    $rad2 = ($angle + 15) * [Math]::PI / 180
    
    $x1 = 36 + [Math]::Cos($rad1) * 22
    $y1 = 36 + [Math]::Sin($rad1) * 22
    $x2 = 36 + [Math]::Cos($rad2) * 22
    $y2 = 36 + [Math]::Sin($rad2) * 22
    
    $x3 = 36 + [Math]::Cos($rad2) * 18
    $y3 = 36 + [Math]::Sin($rad2) * 18
    $x4 = 36 + [Math]::Cos($rad1) * 18
    $y4 = 36 + [Math]::Sin($rad1) * 18
    
    $g.DrawLine($gearPen, $x1, $y1, $x2, $y2)
    $g.DrawLine($gearPen, $x2, $y2, $x3, $y3)
}

# Inner circle (coral)
$g.DrawEllipse($coralBrush, 28, 28, 16, 16)

Save-Icon -Bitmap $bmp -Name "config"
$g.Dispose()

# 9. Session - Chat bubbles
$bmp = New-IconCanvas
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.Clear([System.Drawing.Color]::Transparent)

# First bubble (white, lower left)
$bubble1Rect = [System.Drawing.Rectangle]::new(16, 30, 28, 22)
Draw-RoundedRect -Graphics $g -Brush $whiteBrush -Rect $bubble1Rect -Radius 4
# Tail
$g.FillPolygon($whiteBrush, @([System.Drawing.Point]::new(16, 44), [System.Drawing.Point]::new(16, 50), [System.Drawing.Point]::new(22, 46)))

# Second bubble (coral, upper right)
$bubble2Rect = [System.Drawing.Rectangle]::new(28, 20, 28, 22)
$coralBrush = New-Object System.Drawing.SolidBrush($Coral)
Draw-RoundedRect -Graphics $g -Brush $coralBrush -Rect $bubble2Rect -Radius 4

Save-Icon -Bitmap $bmp -Name "session"
$g.Dispose()

# 10. Web Search - Magnifying glass
$bmp = New-IconCanvas
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.Clear([System.Drawing.Color]::Transparent)

# Glass circle (white outline)
$glassPen = New-Object System.Drawing.Pen($White, 4)
$glassPen.Cap = [System.Drawing.Drawing2D.LineCap]::Round
$g.DrawEllipse($glassPen, 20, 18, 26, 26)

# Handle (coral)
$handlePen = New-Object System.Drawing.Pen($Coral, 4)
$handlePen.Cap = [System.Drawing.Drawing2D.LineCap]::Round
$rad = 45 * [Math]::PI / 180
$x = 38 + [Math]::Cos($rad) * 13
$y = 36 + [Math]::Sin($rad) * 13
$g.DrawLine($handlePen, $x, $y, 54, 52)

Save-Icon -Bitmap $bmp -Name "websearch"
$g.Dispose()

Write-Host ""
Write-Host "All icons generated successfully!" -ForegroundColor Green
Write-Host "Location: $IconDir" -ForegroundColor Cyan

# List created files
Get-ChildItem $IconDir -Filter "*.png" | ForEach-Object {
    $size = $_.Length
    Write-Host "  - $($_.Name) ($([math]::Round($size/1024, 1)) KB)" -ForegroundColor White
}
