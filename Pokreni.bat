@echo off
setlocal enabledelayedexpansion
title YouTube skidac
cd /d "%~dp0"
set "PATH=%~dp0;%PATH%"
set "YTDLP=%~dp0yt-dlp.exe"
set "CFG=%~dp0podesavanja.txt"
set "RADNI=%~dp0temp"
if not exist "%RADNI%" mkdir "%RADNI%"

if not exist "%YTDLP%" goto priprema
if not exist "%~dp0ffmpeg.exe" goto priprema
if not exist "%~dp0deno.exe" goto priprema
goto posle

:priprema
echo.
echo ==================================================
echo   PRVO POKRETANJE
echo   Skidam potrebne programe (oko 150 MB).
echo   Traje par minuta, i radi se samo jednom.
echo ==================================================
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0priprema.ps1"
if not exist "%YTDLP%" (
  echo.
  echo Nije uspelo. Proveri internet pa pokreni ponovo.
  pause
  exit /b
)

:posle
if not exist "%CFG%" call :podesavanje
for /f "usebackq tokens=1,* delims==" %%a in ("%CFG%") do set "%%a=%%b"
if not exist "!FOLDER!" mkdir "!FOLDER!"

:pocetak
del /q "%RADNI%\*.*" >nul 2>&1
echo.
echo ==================================================
echo    1 = samo zvuk (MP3)
echo    2 = video (MP4)
echo    3 = promeni podesavanja
echo    4 = azuriraj program
echo    Enter bez broja = izlaz
echo ==================================================
echo   Snima u: !FOLDER!
if defined DRIVE echo   Drive:   !DRIVE!
echo.
set "IZBOR="
set /p "IZBOR=Izaberi: "
if not defined IZBOR goto kraj
if "!IZBOR!"=="3" (
  call :podesavanje
  for /f "usebackq tokens=1,* delims==" %%a in ("%CFG%") do set "%%a=%%b"
  goto pocetak
)
if "!IZBOR!"=="4" (
  echo.
  "%YTDLP%" -U
  echo.
  pause
  goto pocetak
)
if not "!IZBOR!"=="1" if not "!IZBOR!"=="2" (
  echo Upisi 1, 2, 3 ili 4.
  goto pocetak
)

set "LINK="
set /p "LINK=Nalepi link: "
if not defined LINK goto pocetak

echo.
echo Skidam, sacekaj...
echo.

if "!IZBOR!"=="1" (
  set "TIP=*.mp3"
  set "PODFOLDER=Muzika"
) else (
  set "TIP=*.mp4"
  set "PODFOLDER=Video"
)

call :skini
if not errorlevel 1 goto uspelo

rem Nije proslo bez prijave (npr. video sa ogranicenjem godina).
rem Probaj ponovo sa YouTube prijavom iz nekog od browsera.
for %%B in (firefox edge chrome brave) do (
  echo.
  echo Probam ponovo sa prijavom iz browsera: %%B ...
  echo.
  del /q "%RADNI%\*.*" >nul 2>&1
  call :skini --cookies-from-browser %%B
  if not errorlevel 1 goto uspelo
)

echo.
echo NIJE USPELO.
echo Ako se ovo ponavlja, izaberi opciju 4 pa pokusaj opet.
echo Ako je video sa ogranicenjem godina: uloguj se na YouTube
echo u Firefox-u (nalog mora biti punoletan) i probaj opet.
goto pocetak

:uspelo

set "CILJ=!FOLDER!\!PODFOLDER!"
if not exist "!CILJ!" mkdir "!CILJ!"
copy /y "%RADNI%\!TIP!" "!CILJ!\" >nul
echo.
echo Snimljeno: !CILJ!
echo.

if defined DRIVE (
  set "SALJI="
  set /p "SALJI=Poslati kopiju na Google Drive? (d/n): "
  if /i "!SALJI!"=="d" (
    if exist "!DRIVE!" (
      if not exist "!DRIVE!\!PODFOLDER!" mkdir "!DRIVE!\!PODFOLDER!"
      copy /y "%RADNI%\!TIP!" "!DRIVE!\!PODFOLDER!\" >nul
      echo Poslato na Drive.
    ) else (
      echo Drive trenutno nije dostupan. Pokreni Google Drive aplikaciju.
    )
  )
)
goto pocetak

:podesavanje
echo.
echo ==================================================
echo   PODESAVANJE
echo ==================================================
echo.
echo Sada ce se otvoriti prozor za biranje foldera
echo u koji ce se snimati fajlovi.
echo.
pause

set "IZABRAN="
for /f "delims=" %%i in ('powershell -NoProfile -STA -Command "Add-Type -AssemblyName System.Windows.Forms; $f=New-Object System.Windows.Forms.FolderBrowserDialog; $f.Description='Izaberi folder za snimanje'; $null=$f.ShowDialog(); $f.SelectedPath"') do set "IZABRAN=%%i"
if not defined IZABRAN set "IZABRAN=%USERPROFILE%\Desktop\YouTube"

set "NADJEN="
for %%d in (D E F G H I J K L M N O P Q R S T U V W X Y Z) do (
  if exist "%%d:\My Drive" set "NADJEN=%%d:\My Drive"
  if exist "%%d:\Moj disk" set "NADJEN=%%d:\Moj disk"
)

set "DRIVEPUT="
if defined NADJEN (
  echo.
  echo Pronadjen je Google Drive: !NADJEN!
  set "ODG="
  set /p "ODG=Zelis li da mozes da saljes kopije tamo? (d/n): "
  if /i "!ODG!"=="d" (
    echo.
    echo Sada izaberi folder na Google Drive-u...
    for /f "delims=" %%j in ('powershell -NoProfile -STA -Command "Add-Type -AssemblyName System.Windows.Forms; $f=New-Object System.Windows.Forms.FolderBrowserDialog; $f.Description='Izaberi folder na Google Drive-u'; $f.SelectedPath='!NADJEN!'; $f.ShowNewFolderButton=$true; $null=$f.ShowDialog(); $f.SelectedPath"') do set "DRIVEPUT=%%j"
    if not defined DRIVEPUT set "DRIVEPUT=!NADJEN!\YouTube"
  )
) else (
  echo.
  echo Google Drive nije pronadjen na ovom racunaru.
  echo Ako ga zelis: instaliraj "Google Drive za racunar"
  echo sa google.com/drive/download, prijavi se, pa ovde
  echo izaberi opciju 3 za ponovno podesavanje.
)

> "%CFG%" echo FOLDER=!IZABRAN!
>> "%CFG%" echo DRIVE=!DRIVEPUT!
echo.
echo Sacuvano.
echo.
pause
goto :eof

:kraj
del /q "%RADNI%\*.*" >nul 2>&1
exit /b

:skini
rem %* = dodatni parametri (npr. --cookies-from-browser firefox)
if "!IZBOR!"=="1" (
  "%YTDLP%" %* -x --audio-format mp3 --audio-quality 0 --no-playlist -P "home:%RADNI%" -o "%%(title)s.%%(ext)s" "!LINK!"
) else (
  "%YTDLP%" %* -f "bv*[ext=mp4]+ba[ext=m4a]/b[ext=mp4]/b" --merge-output-format mp4 --no-playlist -P "home:%RADNI%" -o "%%(title)s.%%(ext)s" "!LINK!"
)
exit /b !errorlevel!

