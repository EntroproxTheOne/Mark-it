# Copies photos from your library into assets/demo_gallery/ and resizes for APK size.
# Source: adjust if your folder path differs.
$src = "E:\BEST PICS OF ALL TIME"
$dest = Join-Path $PSScriptRoot "..\assets\demo_gallery"
$maxW = 1000
$quality = 82

New-Item -ItemType Directory -Force -Path $dest | Out-Null
Add-Type -AssemblyName System.Drawing
$encoder = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq 'image/jpeg' }
$encoderParams = New-Object System.Drawing.Imaging.EncoderParameters(1)
$encoderParams.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter([System.Drawing.Imaging.Encoder]::Quality, [int64]$quality)

$imgs = @()
if (Test-Path -LiteralPath $src) {
  $imgs = Get-ChildItem -LiteralPath $src -Recurse -File -ErrorAction SilentlyContinue |
    Where-Object { $_.Extension -match '\.(jpe?g|png|webp)$' } |
    Sort-Object Length -Descending |
    Select-Object -First 8
}

if ($imgs.Count -eq 0) {
  Write-Host "No images under $src — add photos there or edit `$src in this script."
  exit 1
}

$n = 0
foreach ($f in $imgs) {
  $n++
  $ext = $f.Extension.ToLower()
  if ($ext -eq ".jpeg") { $ext = ".jpg" }
  if ($ext -eq ".png" -or $ext -eq ".webp") { $ext = ".jpg" }
  $outPath = Join-Path $dest ("demo_{0:D2}{1}" -f $n, $ext)

  $img = $null
  $bmp = $null
  $g = $null
  try {
    $img = [System.Drawing.Image]::FromFile($f.FullName)
    $ratio = [math]::Min(1.0, $maxW / $img.Width)
    $w = [int]($img.Width * $ratio)
    $h = [int]($img.Height * $ratio)
    $bmp = New-Object System.Drawing.Bitmap $w, $h
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.DrawImage($img, 0, 0, $w, $h)
    $bmp.Save($outPath, $encoder, $encoderParams)
    Write-Host "Wrote $outPath"
  }
  finally {
    if ($null -ne $g) { $g.Dispose() }
    if ($null -ne $bmp) { $bmp.Dispose() }
    if ($null -ne $img) { $img.Dispose() }
  }
}

Write-Host "Done. Run: flutter pub get && flutter build apk ..."
