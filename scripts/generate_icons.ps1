Add-Type -AssemblyName System.Drawing

function Create-Icon($srcPath, $destPath, $size, $radiusRatio = 0.22, $clipRounded = $false, $bgColor = [System.Drawing.Color]::Black) {
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

    if ($clipRounded) {
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
        # Solid background (e.g., Black for iOS / AppStore / Raw master logo)
        $g.Clear($bgColor)
        $g.DrawImage($src, 0, 0, $size, $size)
    }

    $dest.Save($destPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $g.Dispose()
    $dest.Dispose()
    $src.Dispose()
}

function Create-WindowsIcon($srcPath, $destPath) {
    $destDir = Split-Path -Parent $destPath
    if (-not (Test-Path $destDir)) {
        New-Item -ItemType Directory -Path $destDir -Force | Out-Null
    }

    $src = [System.Drawing.Image]::FromFile($srcPath)
    $dest = New-Object System.Drawing.Bitmap(256, 256, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($dest)
    $g.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.Clear([System.Drawing.Color]::Black)
    $g.DrawImage($src, 0, 0, 256, 256)
    
    $hIcon = $dest.GetHicon()
    $icon = [System.Drawing.Icon]::FromHandle($hIcon)
    $fs = New-Object System.IO.FileStream($destPath, [System.IO.FileMode]::Create)
    $icon.Save($fs)
    $fs.Close()
    $icon.Dispose()
    $g.Dispose()
    $dest.Dispose()
    $src.Dispose()
}

$sourceImage = "C:\Users\shrey\.gemini\antigravity-ide\brain\12975f39-a7a5-4d46-9e29-575a705ccb2c\.user_uploaded\media_1788542656172.jpg"

if (-not (Test-Path $sourceImage)) {
    Write-Error "Source image not found: $sourceImage"
    exit 1
}

Write-Host "Source image: $sourceImage"

Write-Host "Generating master logo.png..."
Create-Icon $sourceImage "c:\vh\assets\images\logo.png" 1024 0.22 $false

Write-Host "Generating Android mipmap icons..."
Create-Icon $sourceImage "c:\vh\android\app\src\main\res\mipmap-mdpi\ic_launcher.png" 48 0.22 $true
Create-Icon $sourceImage "c:\vh\android\app\src\main\res\mipmap-hdpi\ic_launcher.png" 72 0.22 $true
Create-Icon $sourceImage "c:\vh\android\app\src\main\res\mipmap-xhdpi\ic_launcher.png" 96 0.22 $true
Create-Icon $sourceImage "c:\vh\android\app\src\main\res\mipmap-xxhdpi\ic_launcher.png" 144 0.22 $true
Create-Icon $sourceImage "c:\vh\android\app\src\main\res\mipmap-xxxhdpi\ic_launcher.png" 192 0.22 $true

Write-Host "Generating Web icons..."
Create-Icon $sourceImage "c:\vh\web\icons\Icon-192.png" 192 0.22 $true
Create-Icon $sourceImage "c:\vh\web\icons\Icon-512.png" 512 0.22 $true
Create-Icon $sourceImage "c:\vh\web\icons\Icon-maskable-192.png" 192 0.22 $false
Create-Icon $sourceImage "c:\vh\web\icons\Icon-maskable-512.png" 512 0.22 $false
Create-Icon $sourceImage "c:\vh\web\favicon.png" 32 0.22 $true

Write-Host "Generating iOS icons (solid black, AppStore compliant)..."
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

Write-Host "Generating macOS icons..."
Create-Icon $sourceImage "c:\vh\macos\Runner\Assets.xcassets\AppIcon.appiconset\app_icon_1024.png" 1024 0.22 $false
Create-Icon $sourceImage "c:\vh\macos\Runner\Assets.xcassets\AppIcon.appiconset\app_icon_512.png" 512 0.22 $false
Create-Icon $sourceImage "c:\vh\macos\Runner\Assets.xcassets\AppIcon.appiconset\app_icon_256.png" 256 0.22 $false
Create-Icon $sourceImage "c:\vh\macos\Runner\Assets.xcassets\AppIcon.appiconset\app_icon_128.png" 128 0.22 $false
Create-Icon $sourceImage "c:\vh\macos\Runner\Assets.xcassets\AppIcon.appiconset\app_icon_64.png" 64 0.22 $false
Create-Icon $sourceImage "c:\vh\macos\Runner\Assets.xcassets\AppIcon.appiconset\app_icon_32.png" 32 0.22 $false
Create-Icon $sourceImage "c:\vh\macos\Runner\Assets.xcassets\AppIcon.appiconset\app_icon_16.png" 16 0.22 $false

Write-Host "Generating Windows icon..."
try {
    Create-WindowsIcon $sourceImage "c:\vh\windows\runner\resources\app_icon.ico"
    Write-Host "Windows icon generated successfully."
} catch {
    Write-Warning "Windows icon generation fallback: $_"
}

Write-Host "Updating adaptq_logo.svg..."
$bytes = [System.IO.File]::ReadAllBytes("c:\vh\assets\images\logo.png")
$b64 = [Convert]::ToBase64String($bytes)
$svgContent = @"
<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 1024 1024" role="img" aria-label="AdaptQ logo">
  <rect width="1024" height="1024" fill="#000000"/>
  <image width="1024" height="1024" xlink:href="data:image/png;base64,$b64"/>
</svg>
"@
[System.IO.File]::WriteAllText("c:\vh\assets\images\adaptq_logo.svg", $svgContent)
Write-Host "adaptq_logo.svg updated successfully."

Write-Host "All icons generated successfully!"

