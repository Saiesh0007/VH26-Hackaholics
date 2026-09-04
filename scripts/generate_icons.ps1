Add-Type -AssemblyName System.Drawing

function Create-Icon($srcPath, $destPath, $size, $radiusRatio = 0.22, $transparent = $true) {
    $destDir = Split-Path -Parent $destPath
    if (-not (Test-Path $destDir)) {
        New-Item -ItemType Directory -Path $destDir -Force | Out-Null
    }

    $src = [System.Drawing.Image]::FromFile($srcPath)
    $dest = New-Object System.Drawing.Bitmap($size, $size, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($dest)
    $g.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality

    if ($transparent) {
        $g.Clear([System.Drawing.Color]::Transparent)
        $r = [Math]::Round($size * $radiusRatio)
        $d = $r * 2
        $path = New-Object System.Drawing.Drawing2D.GraphicsPath
        $path.AddArc(0, 0, $d, $d, 180, 90)
        $path.AddArc($size - $d, 0, $d, $d, 270, 90)
        $path.AddArc($size - $d, $size - $d, $d, $d, 0, 90)
        $path.AddArc(0, $size - $d, $d, $d, 90, 90)
        $path.CloseFigure()

        $g.SetClip($path)
        $g.DrawImage($src, 0, 0, $size, $size)
        $g.ResetClip()
        $path.Dispose()
    } else {
        # Solid background for iOS / App Store (no alpha channel allowed)
        $g.Clear([System.Drawing.Color]::FromArgb(210, 228, 252))
        $g.DrawImage($src, 0, 0, $size, $size)
    }

    $dest.Save($destPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $g.Dispose()
    $dest.Dispose()
    $src.Dispose()
}

$sourceImage = "C:\Users\shrey\.gemini\antigravity-ide\brain\f8aeb9d5-eac1-49f3-b942-03140ef7a854\.user_uploaded\media_1788525694024.jpg"

Write-Host "Generating master logo.png..."
Create-Icon $sourceImage "c:\vh\assets\images\logo.png" 1024 0.22 $true

Write-Host "Generating Android mipmap icons..."
Create-Icon $sourceImage "c:\vh\android\app\src\main\res\mipmap-mdpi\ic_launcher.png" 48 0.22 $true
Create-Icon $sourceImage "c:\vh\android\app\src\main\res\mipmap-hdpi\ic_launcher.png" 72 0.22 $true
Create-Icon $sourceImage "c:\vh\android\app\src\main\res\mipmap-xhdpi\ic_launcher.png" 96 0.22 $true
Create-Icon $sourceImage "c:\vh\android\app\src\main\res\mipmap-xxhdpi\ic_launcher.png" 144 0.22 $true
Create-Icon $sourceImage "c:\vh\android\app\src\main\res\mipmap-xxxhdpi\ic_launcher.png" 192 0.22 $true

Write-Host "Generating Web icons..."
Create-Icon $sourceImage "c:\vh\web\icons\Icon-192.png" 192 0.22 $true
Create-Icon $sourceImage "c:\vh\web\icons\Icon-512.png" 512 0.22 $true
Create-Icon $sourceImage "c:\vh\web\icons\Icon-maskable-192.png" 192 0.22 $true
Create-Icon $sourceImage "c:\vh\web\icons\Icon-maskable-512.png" 512 0.22 $true
Create-Icon $sourceImage "c:\vh\web\favicon.png" 32 0.22 $true

Write-Host "Generating iOS icons (solid, AppStore compliant)..."
Create-Icon $sourceImage "c:\vh\ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-1024x1024@1x.png" 1024 0.22 $false
Create-Icon $sourceImage "c:\vh\ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-20x20@1x.png" 20 0.22 $false
Create-Icon $sourceImage "c:\vh\ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-20x20@2x.png" 40 0.22 $false
Create-Icon $sourceImage "c:\vh\ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-20x20@3x.png" 60 0.22 $false
Create-Icon $sourceImage "c:\vh\ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-29x29@1x.png" 29 0.22 $false
Create-Icon $sourceImage "c:\vh\ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-29x29@2x.png" 58 0.22 $false
Create-Icon $sourceImage "c:\vh\ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-29x29@3x.png" 87 0.22 $false
Create-Icon $sourceImage "c:\vh\ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-40x40@1x.png" 40 0.22 $false
Create-Icon $sourceImage "c:\vh\ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-40x40@2x.png" 80 0.22 $false
Create-Icon $sourceImage "c:\vh\ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-40x40@3x.png" 120 0.22 $false
Create-Icon $sourceImage "c:\vh\ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-60x60@2x.png" 120 0.22 $false
Create-Icon $sourceImage "c:\vh\ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-60x60@3x.png" 180 0.22 $false
Create-Icon $sourceImage "c:\vh\ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-76x76@1x.png" 76 0.22 $false
Create-Icon $sourceImage "c:\vh\ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-76x76@2x.png" 152 0.22 $false
Create-Icon $sourceImage "c:\vh\ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-83.5x83.5@2x.png" 167 0.22 $false

Write-Host "All icons generated successfully!"
