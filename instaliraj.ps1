# Instalira (ili azurira) YouTube skidac.
# Pokrece ga Instaliraj-YouTube-Skidac.bat, posle skidanja ovog projekta sa GitHub-a.
# Kopira skripte u %LOCALAPPDATA%\YouTube-Skidac, skine potrebne programe,
# napravi precice u Start meniju i na Desktop-u, i pokrene skidac.
# Kod azuriranja zadrzava podesavanja i vec skinute programe.
$ErrorActionPreference = "Stop"

# Za probu se mesta mogu promeniti promenljivama SKIDAC_CILJ, SKIDAC_START, SKIDAC_DESKTOP
# i SKIDAC_BEZ_POKRETANJA=1; inace se koriste uobicajena mesta.
function Mesto($promenljiva, $podrazumevano) {
  $v = [Environment]::GetEnvironmentVariable($promenljiva)
  if ($v) { return $v } else { return $podrazumevano }
}
$Cilj = Mesto "SKIDAC_CILJ" (Join-Path $env:LOCALAPPDATA "YouTube-Skidac")
$StartMeni = Mesto "SKIDAC_START" ([Environment]::GetFolderPath("Programs"))
$Desktop = Mesto "SKIDAC_DESKTOP" ([Environment]::GetFolderPath("Desktop"))
$BezPokretanja = [Environment]::GetEnvironmentVariable("SKIDAC_BEZ_POKRETANJA") -eq "1"
$izvor = $PSScriptRoot

$azuriranje = Test-Path (Join-Path $Cilj "Pokreni.bat")
if ($azuriranje) { Write-Host "Azuriram skidac u: $Cilj" } else { Write-Host "Instaliram skidac u: $Cilj" }
New-Item -ItemType Directory $Cilj -Force | Out-Null

foreach ($f in "Pokreni.bat", "priprema.ps1", "kvalitet.ps1", "sporteurope.ps1", "Procitaj-me.txt") {
  Copy-Item (Join-Path $izvor $f) $Cilj -Force
}

Write-Host ""
& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $Cilj "priprema.ps1")
if (-not (Test-Path (Join-Path $Cilj "yt-dlp.exe"))) {
  throw "Nisu skinuti potrebni programi. Proveri internet pa pokreni instalaciju ponovo."
}

$shell = New-Object -ComObject WScript.Shell
foreach ($folder in $StartMeni, $Desktop) {
  if (-not $folder) { continue }
  $p = $shell.CreateShortcut((Join-Path $folder "YouTube Skidac.lnk"))
  $p.TargetPath = Join-Path $Cilj "Pokreni.bat"
  $p.WorkingDirectory = $Cilj
  $p.IconLocation = (Join-Path $Cilj "yt-dlp.exe") + ",0"
  $p.Description = "Skidanje zvuka i videa sa YouTube-a i drugih sajtova"
  $p.Save()
}

Write-Host ""
Write-Host "=================================================="
Write-Host "  GOTOVO!"
Write-Host "  Skidac pokreces preko precice 'YouTube Skidac'"
Write-Host "  na Desktop-u ili u Start meniju."
Write-Host "=================================================="

if (-not $BezPokretanja) {
  Start-Process -FilePath (Join-Path $Cilj "Pokreni.bat") -WorkingDirectory $Cilj
}
