param(
    [string]$PackageName = "xyz.aethersx2.android",
    [string]$CheatDirectory = (Join-Path $PSScriptRoot "..\cheats\exact"),
    [string]$CandidateDirectory = (Join-Path $PSScriptRoot "..\cheats\candidates"),
    [string]$Device,
    [switch]$IncludeCandidates,
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

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

$remoteCheatDirectory = "/sdcard/Android/data/$PackageName/files/cheats"
$sourceDirectories = @((Resolve-Path $CheatDirectory).Path)

if ($IncludeCandidates) {
    if (-not (Test-Path $CandidateDirectory)) {
        throw "Candidate cheat directory not found: $CandidateDirectory"
    }
    $sourceDirectories += (Resolve-Path $CandidateDirectory).Path
}

$files = foreach ($directory in $sourceDirectories) {
    Get-ChildItem -LiteralPath $directory -Filter "*.pnach" -File
}

if (-not $files) {
    throw "No .pnach files found."
}

Invoke-Adb shell "mkdir -p '$remoteCheatDirectory'"

foreach ($file in $files) {
    $remotePath = "$remoteCheatDirectory/$($file.Name)"
    Invoke-Adb push $file.FullName $remotePath
}

Invoke-Adb shell "find '$remoteCheatDirectory' -type f -name '*.pnach' -exec chmod 660 {} +"

Write-Host "Installed $($files.Count) PNACH file(s) to $remoteCheatDirectory"
if ($IncludeCandidates) {
    Write-Host "Included candidate cheats. Test these in-game before moving them to cheats\exact."
}
