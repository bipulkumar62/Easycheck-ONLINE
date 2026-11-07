Add-Type -AssemblyName System.Drawing

$root = Split-Path -Parent $PSScriptRoot
$markPath = Join-Path $root 'assets\images\easycheck_logo_mark_square.png'
$outDir = Join-Path $root 'store_assets'
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

function New-RoundedRectPath {
    param(
        [System.Drawing.RectangleF]$Rect,
        [float]$Radius
    )
    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $d = $Radius * 2
    $path.AddArc($Rect.X, $Rect.Y, $d, $d, 180, 90)
    $path.AddArc($Rect.Right - $d, $Rect.Y, $d, $d, 270, 90)
    $path.AddArc($Rect.Right - $d, $Rect.Bottom - $d, $d, $d, 0, 90)
    $path.AddArc($Rect.X, $Rect.Bottom - $d, $d, $d, 90, 90)
    $path.CloseFigure()
    return $path
}

# ---------- Play Store icon: 512 x 512, white plate, centered mark ----------
$mark = [System.Drawing.Bitmap]::FromFile($markPath)
$icon = New-Object System.Drawing.Bitmap(512, 512, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g = [System.Drawing.Graphics]::FromImage($icon)
$g.Clear([System.Drawing.Color]::White)
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
$g.DrawImage($mark, (New-Object System.Drawing.Rectangle(56, 56, 400, 400)), (New-Object System.Drawing.Rectangle(0, 0, $mark.Width, $mark.Height)), [System.Drawing.GraphicsUnit]::Pixel)
$g.Dispose()
$icon.Save((Join-Path $outDir 'app_icon_512.png'), [System.Drawing.Imaging.ImageFormat]::Png)
$icon.Dispose()
$mark.Dispose()

# ---------- Feature graphic: 1024 x 500 ----------
$w = 1024
$h = 500
$fg = New-Object System.Drawing.Bitmap($w, $h, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g = [System.Drawing.Graphics]::FromImage($fg)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
$g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit

$rect = New-Object System.Drawing.Rectangle(0, 0, $w, $h)
$bgBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush($rect, [System.Drawing.Color]::FromArgb(255, 3, 20, 40), [System.Drawing.Color]::FromArgb(255, 9, 66, 120), 20.0)
$g.FillRectangle($bgBrush, $rect)
$bgBrush.Dispose()

# Soft glows
$glow1 = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(38, 140, 232, 188))
$g.FillEllipse($glow1, 640, -150, 620, 620)
$glow1.Dispose()
$glow2 = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(30, 125, 247, 182))
$g.FillEllipse($glow2, -180, 260, 560, 560)
$glow2.Dispose()

# Right-side logo card
$cardRect = New-Object System.Drawing.RectangleF(714, 108, 252, 252)
$cardPath = New-RoundedRectPath -Rect $cardRect -Radius 46
$cardShadow = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(55, 0, 0, 0))
$shadowPath = New-RoundedRectPath -Rect (New-Object System.Drawing.RectangleF(722, 118, 252, 252)) -Radius 46
$g.FillPath($cardShadow, $shadowPath)
$cardShadow.Dispose()
$shadowPath.Dispose()
$cardBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
$g.FillPath($cardBrush, $cardPath)
$cardBrush.Dispose()

$mark2 = [System.Drawing.Bitmap]::FromFile($markPath)
$g.DrawImage($mark2, (New-Object System.Drawing.Rectangle(740, 134, 200, 200)), (New-Object System.Drawing.Rectangle(0, 0, $mark2.Width, $mark2.Height)), [System.Drawing.GraphicsUnit]::Pixel)
$mark2.Dispose()
$cardPath.Dispose()

# Eyebrow
$mint = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 140, 232, 188))
$dotBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 140, 232, 188))
$g.FillEllipse($dotBrush, 74, 96, 10, 10)
$dotBrush.Dispose()
$fontEyebrow = New-Object System.Drawing.Font('Segoe UI', 13, [System.Drawing.FontStyle]::Bold)
$g.DrawString('CARE, CONNECTED', $fontEyebrow, $mint, 96, 88)
$fontEyebrow.Dispose()

# Title
$white = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
$fontTitle = New-Object System.Drawing.Font('Segoe UI', 46, [System.Drawing.FontStyle]::Bold)
$g.DrawString('EasyCheck Online', $fontTitle, $white, 68, 122)
$fontTitle.Dispose()

# Subtitle
$soft = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(235, 255, 255, 255))
$fontSub = New-Object System.Drawing.Font('Segoe UI', 19, [System.Drawing.FontStyle]::Regular)
$g.DrawString('Live parchi tracking for clinics and patients', $fontSub, $soft, 72, 216)
$fontSub.Dispose()

# Feature chips
$chipFont = New-Object System.Drawing.Font('Segoe UI', 12.5, [System.Drawing.FontStyle]::Bold)
$chipText = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 215, 248, 231))
$chipFill = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(34, 255, 255, 255))
$chipLine = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(55, 255, 255, 255), 1)
$chips = @(
    @{ Text = 'LIVE QUEUE'; X = 72; W = 142 },
    @{ Text = 'DOCTOR TIMING'; X = 226; W = 178 },
    @{ Text = 'CLINIC ACCESS'; X = 416; W = 168 }
)
foreach ($chip in $chips) {
    $r = New-Object System.Drawing.RectangleF($chip.X, 300, $chip.W, 40)
    $p = New-RoundedRectPath -Rect $r -Radius 20
    $g.FillPath($chipFill, $p)
    $g.DrawPath($chipLine, $p)
    $g.DrawString($chip.Text, $chipFont, $chipText, ($chip.X + 16), 309)
    $p.Dispose()
}
$chipFont.Dispose()
$chipText.Dispose()
$chipFill.Dispose()
$chipLine.Dispose()

# Bottom rule + small line
$linePen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(40, 255, 255, 255), 1)
$g.DrawLine($linePen, 72, 392, 584, 392)
$linePen.Dispose()
$fontFoot = New-Object System.Drawing.Font('Segoe UI', 11.5, [System.Drawing.FontStyle]::Regular)
$footBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(170, 255, 255, 255))
$g.DrawString('Simple for patients. Powerful for clinic teams.', $fontFoot, $footBrush, 72, 406)
$fontFoot.Dispose()
$footBrush.Dispose()

$white.Dispose()
$soft.Dispose()
$mint.Dispose()
$g.Dispose()
$fg.Save((Join-Path $outDir 'feature_graphic_1024x500.png'), [System.Drawing.Imaging.ImageFormat]::Png)
$fg.Dispose()

# Report
Get-ChildItem $outDir -File | ForEach-Object {
    $i = [System.Drawing.Image]::FromFile($_.FullName)
    "$($_.Name)  $($i.Width)x$($i.Height)  $([math]::Round($_.Length/1KB,1))KB"
    $i.Dispose()
}
