param(
    [string]$Package = "xyz.aethersx2.android",
    [string]$Adb = "adb"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$cheatDir = "/sdcard/Android/data/$Package/files/cheats"
$script = "if [ -d '$cheatDir' ]; then find '$cheatDir' -type f -name '*.pnach' -exec chmod 660 {} +; else echo 'Missing cheats dir: $cheatDir' >&2; exit 1; fi"

& $Adb shell $script
if ($LASTEXITCODE -ne 0) {
    throw "Failed to chmod PNACH files in $cheatDir"
}

Write-Host "PNACH cheat files are group-writable in $cheatDir"
