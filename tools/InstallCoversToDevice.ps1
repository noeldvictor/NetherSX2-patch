param(
    [string]$PackageName = "xyz.aethersx2.android",
    [string]$GameIndexPath = (Join-Path $PSScriptRoot "..\game_crc_index.tsv"),
    [string]$BaseUrl = 'https://raw.githubusercontent.com/xlenore/ps2-covers/main/covers/default/{serial}.jpg',
    [string]$RemoteNameTemplate = "{title}.{ext}",
    [string]$Device,
    [string]$TempDirectory = (Join-Path $PSScriptRoot "..\dist\cover_downloads"),
    [switch]$PullGameIndex,
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

$adbArgs = @()
if ($Device) {
    $adbArgs += @("-s", $Device)
}

function Invoke-Adb {
    param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Arguments)

    if ($DryRun) {
        Write-Host "adb $($adbArgs + $Arguments -join ' ')"
        return
    }

    & adb @adbArgs @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "adb $($Arguments -join ' ') failed with exit code $LASTEXITCODE"
    }
}

function ConvertTo-CoverFilePart {
    param([string]$Value)

    return (($Value -replace "[/*]", "_").Trim())
}

function Get-CoverExtension {
    param([string]$Url)

    if ($Url -match "\.(jpg|jpeg|png|webp)(?:\?|$)") {
        return $matches[1].ToLowerInvariant()
    }

    return "jpg"
}

function Expand-Template {
    param(
        [string]$Template,
        [pscustomobject]$Game,
        [string]$Extension
    )

    $serial = $Game.serial.Trim()
    $crc = $Game.crc.Trim().ToUpperInvariant()
    $title = ConvertTo-CoverFilePart $Game.title
    $escapedTitle = [uri]::EscapeDataString($Game.title)

    return $Template.
        Replace('${serial}', $serial).
        Replace('{serial}', $serial).
        Replace('${crc}', $crc).
        Replace('{crc}', $crc).
        Replace('${title}', $escapedTitle).
        Replace('{title}', $title).
        Replace('${ext}', $Extension).
        Replace('{ext}', $Extension)
}

$remoteCoverDirectory = "/sdcard/Android/data/$PackageName/files/covers"

if ($PullGameIndex -or -not (Test-Path $GameIndexPath)) {
    $parent = Split-Path -Parent $GameIndexPath
    if ($parent) {
        New-Item -ItemType Directory -Force -Path $parent | Out-Null
    }
    Invoke-Adb pull "/sdcard/Android/data/$PackageName/files/game_crc_index.tsv" $GameIndexPath
}

if (-not (Test-Path $GameIndexPath)) {
    throw "Game CRC index not found: $GameIndexPath"
}

New-Item -ItemType Directory -Force -Path $TempDirectory | Out-Null
Invoke-Adb shell "mkdir -p '$remoteCoverDirectory'"

$games = Import-Csv -Delimiter "`t" -Path $GameIndexPath
$downloaded = 0
$missing = 0

foreach ($game in $games) {
    $url = Expand-Template -Template $BaseUrl -Game $game -Extension ""
    $extension = Get-CoverExtension $url
    $url = Expand-Template -Template $BaseUrl -Game $game -Extension $extension
    $remoteName = Expand-Template -Template $RemoteNameTemplate -Game $game -Extension $extension
    $localPath = Join-Path $TempDirectory "$($game.serial.Trim()).$extension"

    try {
        if (-not $DryRun) {
            Invoke-WebRequest -Uri $url -OutFile $localPath -UseBasicParsing -Headers @{ "User-Agent" = "Mozilla/5.0" }
        } else {
            Write-Host "download $url -> $localPath"
        }

        Invoke-Adb push $localPath "$remoteCoverDirectory/$remoteName"
        $downloaded++
    } catch {
        $missing++
        Write-Warning "No cover installed for $($game.serial) $($game.title): $($_.Exception.Message)"
    }
}

Invoke-Adb shell "find '$remoteCoverDirectory' -type f \( -name '*.jpg' -o -name '*.jpeg' -o -name '*.png' -o -name '*.webp' \) -exec chmod 660 {} +"

Write-Host "Installed $downloaded cover(s) to $remoteCoverDirectory"
if ($missing -gt 0) {
    Write-Host "$missing cover(s) were not available from the configured URL."
}
