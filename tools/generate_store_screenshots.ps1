Add-Type -AssemblyName System.Drawing

$root = Split-Path -Parent $PSScriptRoot
$outDir = Join-Path $root 'store_assets\screenshots'
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

function New-CanvasScreenshot {
    param(
        [string]$Source,
        [string]$Destination
    )

    $src = [System.Drawing.Bitmap]::FromFile($Source)
    $w = 1080
    $h = 1920
    $bmp = New-Object System.Drawing.Bitmap($w, $h, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality

    $rect = New-Object System.Drawing.Rectangle(0, 0, $w, $h)
    $bg = New-Object System.Drawing.Drawing2D.LinearGradientBrush($rect, [System.Drawing.Color]::FromArgb(255, 3, 20, 40), [System.Drawing.Color]::FromArgb(255, 9, 66, 120), 90.0)
    $g.FillRectangle($bg, $rect)
    $bg.Dispose()

    $glow = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(26, 140, 232, 188))
    $g.FillEllipse($glow, 760, -180, 620, 620)
    $glow.Dispose()

    $scale = $h / $src.Height
    $drawW = [int]($src.Width * $scale)
    $x = [int](($w - $drawW) / 2)

    $shadow = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(70, 0, 0, 0))
    $g.FillRectangle($shadow, ($x - 8), 4, ($drawW + 16), ($h - 4))
    $shadow.Dispose()

    $g.DrawImage($src, (New-Object System.Drawing.Rectangle($x, 0, $drawW, $h)), (New-Object System.Drawing.Rectangle(0, 0, $src.Width, $src.Height)), [System.Drawing.GraphicsUnit]::Pixel)
    $g.Dispose()
    $src.Dispose()
    $bmp.Save($Destination, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
}

New-CanvasScreenshot -Source "$env:TEMP\easycheck-role-android.png" -Destination (Join-Path $outDir 'phone_01_role_selection.png')
New-CanvasScreenshot -Source "$env:TEMP\easycheck-patient3-android.png" -Destination (Join-Path $outDir 'phone_02_patient_login.png')

Get-ChildItem $outDir -File | ForEach-Object {
    $i = [System.Drawing.Image]::FromFile($_.FullName)
    "$($_.Name)  $($i.Width)x$($i.Height)  $([math]::Round($_.Length/1KB,1))KB"
    $i.Dispose()
}
