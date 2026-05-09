param(
    [string]$PackageName = "xyz.aethersx2.android",
    [string]$CheatDirectory = (Join-Path $PSScriptRoot "..\cheats\exact"),
    [string]$CommunityDirectory = (Join-Path $PSScriptRoot "..\cheats\community\xs1l3n7x"),
    [string]$CandidateDirectory = (Join-Path $PSScriptRoot "..\cheats\candidates"),
    [string]$Device,
    [switch]$SkipCommunity,
    [switch]$CommunityOnly,
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
$sourceDirectories = @()

if ($CommunityOnly -and $SkipCommunity) {
    throw "Use either -CommunityOnly or -SkipCommunity, not both."
}

if (-not $SkipCommunity -and (Test-Path -LiteralPath $CommunityDirectory)) {
    $sourceDirectories += (Resolve-Path -LiteralPath $CommunityDirectory).Path
}

if (-not $CommunityOnly) {
    $sourceDirectories += (Resolve-Path -LiteralPath $CheatDirectory).Path
}

if ($IncludeCandidates) {
    if (-not (Test-Path -LiteralPath $CandidateDirectory)) {
        throw "Candidate cheat directory not found: $CandidateDirectory"
    }
    $sourceDirectories += (Resolve-Path -LiteralPath $CandidateDirectory).Path
}

$exactNames = @{}
if ($CommunityOnly) {
    foreach ($exactFile in (Get-ChildItem -LiteralPath $CheatDirectory -Filter "*.pnach" -File)) {
        $exactNames[$exactFile.Name.ToUpperInvariant()] = $true
    }
}

$filesByName = [ordered]@{}
foreach ($directory in $sourceDirectories) {
    foreach ($file in (Get-ChildItem -LiteralPath $directory -Filter "*.pnach" -File | Sort-Object Name)) {
        if ($CommunityOnly -and $exactNames.ContainsKey($file.Name.ToUpperInvariant())) {
            continue
        }
        $filesByName[$file.Name.ToUpperInvariant()] = $file
    }
}
$files = @($filesByName.Values)

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
