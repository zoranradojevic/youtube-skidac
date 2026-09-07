$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
$dir = $PSScriptRoot

if (-not (Test-Path "$dir\yt-dlp.exe")) {
  Write-Host "Skidam yt-dlp..."
  Invoke-WebRequest "https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp.exe" -OutFile "$dir\yt-dlp.exe"
}

if (-not (Test-Path "$dir\ffmpeg.exe")) {
  Write-Host "Skidam ffmpeg, ovo traje najduze..."
  $zip = "$dir\ff.zip"
  Invoke-WebRequest "https://github.com/yt-dlp/FFmpeg-Builds/releases/latest/download/ffmpeg-master-latest-win64-gpl.zip" -OutFile $zip
  Write-Host "Raspakujem..."
  Expand-Archive $zip "$dir\ff" -Force
  foreach ($n in "ffmpeg.exe","ffprobe.exe") {
    $f = Get-ChildItem "$dir\ff" -Recurse -Filter $n | Select-Object -First 1
    if ($f) { Copy-Item $f.FullName $dir -Force }
  }
  Remove-Item $zip -Force
  Remove-Item "$dir\ff" -Recurse -Force
}

Write-Host "Spremno."
