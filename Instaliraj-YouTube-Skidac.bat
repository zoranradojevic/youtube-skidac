@echo off
title YouTube skidac - instalacija
echo.
echo ==================================================
echo   INSTALACIJA YOUTUBE SKIDACA
echo   Skidam program i sve sto mu treba (oko 150 MB).
echo   Traje par minuta.
echo ==================================================
echo.

rem Skine najnoviju verziju sa GitHub-a i pokrene instaliraj.ps1 iz nje.
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; $ProgressPreference='SilentlyContinue'; $t=Join-Path $env:TEMP 'youtube-skidac-instalacija'; if (Test-Path $t) { Remove-Item $t -Recurse -Force }; New-Item -ItemType Directory $t | Out-Null; $z=Join-Path $t 'skidac.zip'; Write-Host 'Skidam skidac sa GitHub-a...'; Invoke-WebRequest 'https://github.com/zoranradojevic/youtube-skidac/archive/refs/heads/main.zip' -OutFile $z -UseBasicParsing; Expand-Archive $z $t; & (Join-Path $t 'youtube-skidac-main\instaliraj.ps1'); Remove-Item $t -Recurse -Force"
if errorlevel 1 (
  echo.
  echo INSTALACIJA NIJE USPELA. Proveri internet pa pokusaj ponovo.
  echo.
  pause
  exit /b 1
)
echo.
pause
