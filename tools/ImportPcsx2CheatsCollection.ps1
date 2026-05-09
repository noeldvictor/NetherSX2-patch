param(
    [string]$SourceDirectory = "",
    [string]$OutputDirectory = "",
    [switch]$Clean
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..")).Path

if ([string]::IsNullOrWhiteSpace($SourceDirectory)) {
    $SourceDirectory = Join-Path $repoRoot ".tmp_pcsx2_cheats_collection\cheats"
}

if ([string]::IsNullOrWhiteSpace($OutputDirectory)) {
    $OutputDirectory = Join-Path $repoRoot "cheats\community\xs1l3n7x"
}

$SourceDirectory = (Resolve-Path -LiteralPath $SourceDirectory).Path

if ($Clean -and (Test-Path -LiteralPath $OutputDirectory)) {
    Remove-Item -LiteralPath $OutputDirectory -Recurse -Force
}

[void](New-Item -ItemType Directory -Path $OutputDirectory -Force)

function Normalize-CheatName {
    param([string]$Name)

    $clean = $Name.Trim()
    $clean = $clean -replace '^Cheats/', ''
    $clean = $clean -replace '[\[\]\r\n]', ''
    $clean = $clean.Trim()

    if ([string]::IsNullOrWhiteSpace($clean)) {
        return "Imported Codes"
    }

    return $clean
}

function Get-SourceCommit {
    $sourceRoot = Split-Path -Parent $SourceDirectory
    try {
        $commit = & git -C $sourceRoot rev-parse --short HEAD 2>$null
        if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace($commit)) {
            return $commit.Trim()
        }
    } catch {
    }

    return "unknown"
}

$sourceFiles = Get-ChildItem -LiteralPath $SourceDirectory -Filter "*.pnach" -File | Sort-Object Name
if (-not $sourceFiles) {
    throw "No PNACH files found in $SourceDirectory"
}

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$imported = 0
$skipped = 0
$totalPatchLines = 0

foreach ($file in $sourceFiles) {
    $baseName = $file.BaseName.ToUpperInvariant()
    if ($baseName -notmatch '(?:^|_)([0-9A-F]{8})$') {
        $skipped++
        continue
    }
    $crc = $Matches[1]

    $groups = [ordered]@{}
    $seenByGroup = @{}
    $currentGroup = "Imported Codes"
    $gameTitle = ""

    foreach ($line in [System.IO.File]::ReadLines($file.FullName)) {
        if ([string]::IsNullOrWhiteSpace($gameTitle) -and $line -match '^\s*gametitle\s*=\s*(.+)$') {
            $gameTitle = $Matches[1].Trim()
            continue
        }

        if ($line -match '^\s*\[(.+)\]\s*$') {
            $currentGroup = Normalize-CheatName $Matches[1]
            continue
        }

        if ($line -notmatch '^\s*(?://\s*)?(patch\s*=\s*[01]\s*,.+?)\s*$') {
            continue
        }

        $patch = $Matches[1].Trim()
        $patch = $patch -replace '^patch\s*=\s*0\s*,', 'patch=1,'
        $patch = $patch -replace '^patch\s*=\s*1\s*,', 'patch=1,'
        $patch = $patch -replace ',\s+', ','

        if (-not $groups.Contains($currentGroup)) {
            $groups[$currentGroup] = New-Object System.Collections.Generic.List[string]
            $seenByGroup[$currentGroup] = New-Object 'System.Collections.Generic.HashSet[string]'
        }

        if ($seenByGroup[$currentGroup].Add($patch)) {
            $groups[$currentGroup].Add($patch)
            $totalPatchLines++
        }
    }

    if ($groups.Count -eq 0) {
        $skipped++
        continue
    }

    $output = New-Object System.Collections.Generic.List[string]
    $output.Add("// Source: https://github.com/xs1l3n7x/pcsx2_cheats_collection")
    if (-not [string]::IsNullOrWhiteSpace($gameTitle)) {
        $output.Add("// Source gametitle: $gameTitle")
    }
    $output.Add("// Imported default-off for NetherSX2 Cheat Helper OSD toggles.")
    $output.Add("")

    foreach ($groupName in $groups.Keys) {
        $output.Add("[Cheats/$groupName]")
        foreach ($patch in $groups[$groupName]) {
            $output.Add("// $patch")
        }
        $output.Add("")
    }

    while ($output.Count -gt 0 -and $output[$output.Count - 1] -eq "") {
        $output.RemoveAt($output.Count - 1)
    }

    $targetPath = Join-Path $OutputDirectory "$crc.pnach"
    [System.IO.File]::WriteAllLines($targetPath, $output, $utf8NoBom)
    $imported++
}

$sourceCommit = Get-SourceCommit
$readme = @"
# xs1l3n7x PCSX2 Cheat Collection Import

Source: https://github.com/xs1l3n7x/pcsx2_cheats_collection
Source commit: $sourceCommit

Imported with tools\ImportPcsx2CheatsCollection.ps1.

The source files are normalized for NetherSX2 Cheat Helper:

- `patch=0,` and `patch=1,` lines become commented `// patch=1,` lines.
- Repeated named blocks are merged into one `[Cheats/<name>]` block.
- Exact curated files in `cheats\exact` override matching community CRC files when bundling the APK.
"@

[System.IO.File]::WriteAllText((Join-Path $OutputDirectory "README.md"), $readme, $utf8NoBom)

$written = @(Get-ChildItem -LiteralPath $OutputDirectory -Filter "*.pnach" -File).Count
Write-Host "Processed $imported source PNACH file(s), wrote $written unique CRC PNACH file(s), skipped $skipped, normalized $totalPatchLines patch line(s)."
