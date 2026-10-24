# Skidanje sa sporteurope.tv
# yt-dlp ima pokvarenu podrsku za ovaj sajt (sajt je promenio API),
# pa ovde sami nadjemo link ka snimku i predamo ga yt-dlp-u.
param(
  [Parameter(Mandatory)][string]$Link,
  [Parameter(Mandatory)][string]$Radni,
  [Parameter(Mandatory)][string]$Izbor,
  [string]$YtDlp = "yt-dlp"
)
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

function Daj-Json($url, $zaglavlja = @{}) {
  $r = Invoke-WebRequest $url -UseBasicParsing -Headers $zaglavlja
  $tekst = [Text.Encoding]::UTF8.GetString($r.RawContentStream.ToArray())
  return $tekst | ConvertFrom-Json
}

try {
  $putanja = ([uri]$Link).AbsolutePath.Trim("/")
  $putanja = $putanja -replace "^[a-z]{2}(-[a-z]{2})?/", ""
  $meta = Daj-Json "https://api.sporteurope.tv/api/web/public/assets/$putanja"
  $plejer = Daj-Json "https://api.sporteurope.tv/api/web-player/personal/assets/$($meta.id)" @{ "x-version" = "2"; "Accept" = "application/json" }
} catch {
  Write-Host "Ne mogu da procitam podatke sa sporteurope.tv: $($_.Exception.Message)"
  exit 1
}

$delovi = @(foreach ($t in $plejer.tracks) { foreach ($s in $t.sources) { if ($s.hls) { $s.hls } } })
if ($delovi.Count -eq 0) {
  Write-Host "Snimak nije dostupan (mozda je PREMIUM, ili prenos jos traje)."
  exit 1
}

$naslov = ($meta.name -replace '[\\/:*?"<>|]', "-").Trim() -replace "%", "%%"
Write-Host "Naslov: $($meta.name)"
if ($delovi.Count -gt 1) { Write-Host "Snimak ima $($delovi.Count) dela." }

$i = 0
foreach ($hls in $delovi) {
  $i++
  $ime = $naslov
  if ($delovi.Count -gt 1) { $ime = "$naslov - Deo $i" }
  $parametri = @("--referer", "https://webplayer.sporteurope.tv/", "--add-headers", "Origin:https://webplayer.sporteurope.tv", "-P", "home:$Radni", "-o", "$ime.%(ext)s")
  if ($Izbor -eq "1") {
    # zvuk je isti u svim kvalitetima, pa uzmi najmanji video
    $parametri += @("-f", "wa/w", "-x", "--audio-format", "mp3", "--audio-quality", "0")
  } else {
    $parametri += @("-f", "bv*+ba/b", "--merge-output-format", "mp4")
  }
  & $YtDlp @parametri $hls
  if ($LASTEXITCODE -ne 0) { exit 1 }
}
exit 0
