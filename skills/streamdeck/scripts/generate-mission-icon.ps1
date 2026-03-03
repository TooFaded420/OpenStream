# Generate Mission Queue Icon
param([int]$Size=72, [string]$OutputPath="$PSScriptRoot\..\assets\icons\mission-queue.png")

Add-Type -AssemblyName System.Drawing

$bitmap = New-Object System.Drawing.Bitmap($Size, $Size)
$graphics = [System.Drawing.Graphics]::FromImage($bitmap)
$graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias

# Background
$bg = [System.Drawing.Brush]::Black
$graphics.FillRectangle($bg, 0, 0, $Size, $Size)

# Calculate dimensions
$padding = [int]($Size * 0.12)
$lineHeight = [int](($Size - ($padding * 2)) / 4)
$boxSize = $lineHeight - 4

# Colors
$green = [System.Drawing.Brush]::FromArgb(138, 255, 122)  # #8aff7a
$dim = [System.Drawing.Brush]::FromArgb(79, 169, 90)       # #4fa95a
$white = [System.Drawing.Brush]::White
$pen = New-Object System.Drawing.Pen($green, 2)

# Draw checkboxes + lines (queue representation)
for ($i = 0; $i -lt 4; $i++) {
    $y = $padding + ($i * $lineHeight) + 2
    $x = $padding
    
    # Checkbox outline
    $graphics.DrawRectangle($pen, $x, $y, $boxSize, $boxSize)
    
    # Checkmark for first two
    if ($i -lt 2) {
        $graphics.DrawLine($pen, $x + 3, $y + $boxSize/2, $x + $boxSize/2, $y + $boxSize - 3)
        $graphics.DrawLine($pen, $x + $boxSize/2, $y + $boxSize - 3, $x + $boxSize - 3, $y + 3)
    }
    
    # Text lines
    $lineY = $y + $boxSize/2
    $graphics.DrawLine($pen, $x + $boxSize + 6, $lineY, $Size - $padding, $lineY)
}

# Plus sign in corner (add mission)
$plusSize = [int]($Size * 0.25)
$plusX = $Size - $padding - $plusSize
$plusY = $Size - $padding - $plusSize
$center = $plusSize / 2
$graphics.DrawLine($pen, $plusX + $center, $plusY + 4, $plusX + $center, $plusY + $plusSize - 4)
$graphics.DrawLine($pen, $plusX + 4, $plusY + $center, $plusX + $plusSize - 4, $plusY + $center)

# Save
$bitmap.Save($OutputPath, [System.Drawing.Imaging.ImageFormat]::Png)
$graphics.Dispose()
$bitmap.Dispose()

Write-Host "Mission Queue icon created: $OutputPath" -ForegroundColor Green
