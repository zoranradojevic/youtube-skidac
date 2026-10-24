# Pita koji kvalitet videa da se skine.
# Pokaze ponudjene visine (1080p, 720p...) sa otprilike velicinom fajla.
# Rezultat (npr. 720) upise u fajl -Izlaz, ili ga vrati ako -Izlaz nije zadat.
# Ako ne moze da procita kvalitete ili ima samo jedan, ne pita nista.
param(
  [Parameter(Mandatory)][string]$Link,
  [string]$YtDlp = "yt-dlp",
  [string]$Izlaz = "",
  [string[]]$Dodatno = @()
)
$najbolje = 10000

function Procitaj($dodatniParametri) {
  $p = @("--no-playlist", "--no-warnings") + $dodatniParametri + @(
    "--print", "%(duration|0)s",
    "--print", "%(formats.:.{height,ext,vcodec,acodec,filesize,filesize_approx,tbr})j",
    $Link)
  $redovi = @(& $YtDlp @p 2>$null)
  if ($LASTEXITCODE -ne 0 -or $redovi.Count -lt 2) { return $null }
  # ForEach-Object raspakuje niz (PowerShell 5.1 ga inace vrati kao jedan objekat)
  return @{ Trajanje = [double]$redovi[0]; Formati = @(($redovi[1] | ConvertFrom-Json) | ForEach-Object { $_ }) }
}

function Velicina($f, $trajanje) {
  if ($f.filesize) { return [double]$f.filesize }
  if ($f.filesize_approx) { return [double]$f.filesize_approx }
  if ($f.tbr -and $trajanje) { return [double]$f.tbr * 1000 / 8 * $trajanje }
  return 0
}

function Zavrsi($visina) {
  if ($Izlaz) { Set-Content -Path $Izlaz -Value $visina -Encoding ascii } else { $visina }
  exit 0
}

Write-Host "Proveravam koji kvaliteti postoje..."
$podaci = Procitaj $Dodatno
if (-not $podaci) {
  # npr. video sa ogranicenjem godina - probaj sa Firefox prijavom
  $podaci = Procitaj ($Dodatno + @("--cookies-from-browser", "firefox"))
}
if (-not $podaci) { Zavrsi $najbolje }

$video = @($podaci.Formati | Where-Object { $_.height -and $_.vcodec -ne "none" })
# skidac vise voli mp4, pa ako postoji, nudi kvalitete iz mp4
$mp4 = @($video | Where-Object { $_.ext -eq "mp4" })
if ($mp4.Count) { $video = $mp4 }

$zvuk = 0
foreach ($f in $podaci.Formati) {
  if ($f.vcodec -eq "none" -and $f.acodec -and $f.acodec -ne "none") {
    $zvuk = [Math]::Max($zvuk, (Velicina $f $podaci.Trajanje))
  }
}

$ponuda = @{}
foreach ($f in $video) {
  $v = [int]$f.height
  $vel = Velicina $f $podaci.Trajanje
  if ($f.acodec -eq "none" -or -not $f.acodec) { $vel += $zvuk }
  if (-not $ponuda.ContainsKey($v) -or $vel -gt $ponuda[$v]) { $ponuda[$v] = $vel }
}
$visine = @($ponuda.Keys | Sort-Object -Descending)
if ($visine.Count -lt 2) { Zavrsi $najbolje }

Write-Host ""
Write-Host "Koji kvalitet?"
for ($i = 0; $i -lt $visine.Count; $i++) {
  $v = $visine[$i]
  $tekst = "   $($i + 1) = $($v)p"
  if ($ponuda[$v] -gt 0) {
    $gb = $ponuda[$v] / 1GB
    if ($gb -ge 1) { $tekst += "  (oko {0:N1} GB)" -f $gb } else { $tekst += "  (oko {0:N0} MB)" -f ($ponuda[$v] / 1MB) }
  }
  if ($i -eq 0) { $tekst += "  <- Enter" }
  Write-Host $tekst
}
while ($true) {
  $odg = (Read-Host "Izaberi").Trim()
  if (-not $odg) { Zavrsi $visine[0] }
  $broj = 0
  if ([int]::TryParse($odg, [ref]$broj) -and $broj -ge 1 -and $broj -le $visine.Count) { Zavrsi $visine[$broj - 1] }
  Write-Host "Upisi broj od 1 do $($visine.Count)."
}
