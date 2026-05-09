param(
    [string]$AssetsPath = "assets",
    [string]$OutputPath = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.IO.Compression.FileSystem

if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $OutputPath = Join-Path $AssetsPath "cheats_index.html"
}

function Get-CheatTitle {
    param([System.IO.Compression.ZipArchiveEntry]$Entry)

    $reader = New-Object System.IO.StreamReader($Entry.Open())
    try {
        while (-not $reader.EndOfStream) {
            $line = $reader.ReadLine()
            if ($line -match '^gametitle\s*=\s*(.+)$') {
                return $Matches[1].Trim()
            }
        }
    } finally {
        $reader.Close()
    }

    return [System.IO.Path]::GetFileNameWithoutExtension($Entry.FullName)
}

function Add-CheatArchive {
    param(
        [hashtable]$Games,
        [string]$ZipPath,
        [string]$FlagName
    )

    $zip = [System.IO.Compression.ZipFile]::OpenRead((Resolve-Path -LiteralPath $ZipPath).Path)
    try {
        foreach ($entry in $zip.Entries) {
            if (-not $entry.FullName.EndsWith(".pnach", [System.StringComparison]::OrdinalIgnoreCase)) {
                continue
            }

            $crc = [System.IO.Path]::GetFileNameWithoutExtension($entry.FullName).ToUpperInvariant()
            $title = Get-CheatTitle -Entry $entry
            if (-not $Games.ContainsKey($crc)) {
                $Games[$crc] = [ordered]@{
                    Crc = $crc
                    Title = $title
                    Widescreen = $false
                    NoInterlacing = $false
                }
            }

            $Games[$crc][$FlagName] = $true
        }
    } finally {
        $zip.Dispose()
    }
}

function Escape-Html {
    param([string]$Text)
    return [System.Net.WebUtility]::HtmlEncode($Text)
}

$games = @{}
Add-CheatArchive -Games $games -ZipPath (Join-Path $AssetsPath "cheats_ws.zip") -FlagName "Widescreen"
Add-CheatArchive -Games $games -ZipPath (Join-Path $AssetsPath "cheats_ni.zip") -FlagName "NoInterlacing"

$sortedGames = $games.Values | Sort-Object @{ Expression = "Title"; Ascending = $true }, @{ Expression = "Crc"; Ascending = $true }
$widescreenCount = @($games.Values | Where-Object { $_.Widescreen }).Count
$noInterlacingCount = @($games.Values | Where-Object { $_.NoInterlacing }).Count
$rows = foreach ($game in $sortedGames) {
    $types = @()
    if ($game.Widescreen) { $types += "Widescreen" }
    if ($game.NoInterlacing) { $types += "No-interlacing" }
    "      <tr><td>$(Escape-Html $game.Title)</td><td><code>$(Escape-Html $game.Crc)</code></td><td>$(Escape-Html ($types -join ', '))</td></tr>"
}

$html = @"
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Bundled patch-supported games</title>
  <style>
    body { font-family: sans-serif; line-height: 1.45; margin: 16px; }
    h1 { font-size: 1.5rem; margin-bottom: 0.25rem; }
    p { margin: 0.5rem 0 1rem; }
    input { box-sizing: border-box; font-size: 1rem; margin: 0 0 12px; padding: 10px; width: 100%; }
    table { border-collapse: collapse; width: 100%; }
    th, td { border-bottom: 1px solid #ddd; padding: 8px 4px; text-align: left; vertical-align: top; }
    th { position: sticky; top: 0; background: #fff; }
    code { white-space: nowrap; }
  </style>
</head>
<body>
  <h1>Bundled patch-supported games</h1>
  <p>Generated from the bundled widescreen and no-interlacing patch archives. Unique games: $($sortedGames.Count). Widescreen: $widescreenCount. No-interlacing: $noInterlacingCount.</p>
  <input id="filter" type="search" placeholder="Search title, CRC, or patch type" oninput="filterRows()">
  <table>
    <thead>
      <tr><th>Game</th><th>CRC</th><th>Available patches</th></tr>
    </thead>
    <tbody id="cheatRows">
$($rows -join "`n")
    </tbody>
  </table>
  <script>
    function filterRows() {
      var query = document.getElementById('filter').value.toLowerCase();
      var rows = document.getElementById('cheatRows').getElementsByTagName('tr');
      for (var i = 0; i < rows.length; i++) {
        rows[i].style.display = rows[i].textContent.toLowerCase().indexOf(query) === -1 ? 'none' : '';
      }
    }
  </script>
</body>
</html>
"@

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText((Join-Path (Get-Location) $OutputPath), $html, $utf8NoBom)
Write-Host "Wrote $OutputPath with $($sortedGames.Count) unique patch-supported games."
