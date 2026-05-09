param(
    [string]$ProjectPath = "",
    [string]$RepoRoot = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($ProjectPath)) {
    if (Test-Path -LiteralPath "4248") {
        $ProjectPath = "4248"
    } elseif (Test-Path -LiteralPath "NetherSX2") {
        $ProjectPath = "NetherSX2"
    } else {
        throw "Could not find a decompiled APK folder. Pass -ProjectPath or run from the decomp folder."
    }
}

if ([string]::IsNullOrWhiteSpace($RepoRoot)) {
    $RepoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..")).Path
}

$ProjectPath = (Resolve-Path -LiteralPath $ProjectPath).Path
$RepoRoot = (Resolve-Path -LiteralPath $RepoRoot).Path
$sourceCheats = Join-Path $RepoRoot "cheats\exact"

if (-not (Test-Path -LiteralPath $sourceCheats)) {
    throw "Missing exact cheat directory: $sourceCheats"
}

$assetCheats = Join-Path $ProjectPath "assets\cheats_exact"
if (Test-Path -LiteralPath $assetCheats) {
    Remove-Item -LiteralPath $assetCheats -Recurse -Force
}
[void](New-Item -ItemType Directory -Path $assetCheats -Force)

$cheatFiles = Get-ChildItem -LiteralPath $sourceCheats -Filter "*.pnach" -File
if (-not $cheatFiles) {
    throw "No exact PNACH files found in $sourceCheats"
}

foreach ($file in $cheatFiles) {
    Copy-Item -LiteralPath $file.FullName -Destination (Join-Path $assetCheats $file.Name) -Force
}

$targetDir = Join-Path $ProjectPath "smali\xyz\aethersx2\android"
[void](New-Item -ItemType Directory -Path $targetDir -Force)

$helperPath = Join-Path $targetDir "BundledCheats.smali"
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$helperSmali = @'
.class public final Lxyz/aethersx2/android/BundledCheats;
.super Ljava/lang/Object;
.source "BundledCheats.java"


# direct methods
.method public constructor <init>()V
    .locals 0

    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    return-void
.end method

.method public static install(Landroid/content/Context;)V
    .locals 15

    :try_start_0
    if-eqz p0, :return

    invoke-virtual {p0}, Landroid/content/Context;->getAssets()Landroid/content/res/AssetManager;

    move-result-object v0

    const-string v1, "cheats_exact"

    invoke-virtual {v0, v1}, Landroid/content/res/AssetManager;->list(Ljava/lang/String;)[Ljava/lang/String;

    move-result-object v2

    if-eqz v2, :return

    array-length v3, v2

    if-lez v3, :return

    const-string v4, "cheats"

    invoke-virtual {p0, v4}, Landroid/content/Context;->getExternalFilesDir(Ljava/lang/String;)Ljava/io/File;

    move-result-object v5

    if-eqz v5, :return

    invoke-virtual {v5}, Ljava/io/File;->mkdirs()Z

    const/16 v6, 0x2000

    new-array v6, v6, [B

    const/4 v7, 0x0

    :loop
    if-ge v7, v3, :return

    aget-object v8, v2, v7

    if-eqz v8, :next

    const-string v9, ".pnach"

    invoke-virtual {v8, v9}, Ljava/lang/String;->endsWith(Ljava/lang/String;)Z

    move-result v9

    if-eqz v9, :next

    new-instance v9, Ljava/io/File;

    invoke-direct {v9, v5, v8}, Ljava/io/File;-><init>(Ljava/io/File;Ljava/lang/String;)V

    invoke-virtual {v9}, Ljava/io/File;->exists()Z

    move-result v10

    if-eqz v10, :copy

    invoke-virtual {v9}, Ljava/io/File;->length()J

    move-result-wide v10

    const-wide/16 v12, 0x0

    cmp-long v14, v10, v12

    if-lez v14, :copy

    goto :next

    :copy
    const-string v10, "cheats_exact/"

    invoke-virtual {v10, v8}, Ljava/lang/String;->concat(Ljava/lang/String;)Ljava/lang/String;

    move-result-object v10

    invoke-virtual {v0, v10}, Landroid/content/res/AssetManager;->open(Ljava/lang/String;)Ljava/io/InputStream;

    move-result-object v10

    new-instance v11, Ljava/io/FileOutputStream;

    invoke-direct {v11, v9}, Ljava/io/FileOutputStream;-><init>(Ljava/io/File;)V

    :copy_loop
    invoke-virtual {v10, v6}, Ljava/io/InputStream;->read([B)I

    move-result v12

    const/4 v13, -0x1

    if-eq v12, v13, :close_streams

    const/4 v13, 0x0

    invoke-virtual {v11, v6, v13, v12}, Ljava/io/FileOutputStream;->write([BII)V

    goto :copy_loop

    :close_streams
    invoke-virtual {v11}, Ljava/io/FileOutputStream;->close()V

    invoke-virtual {v10}, Ljava/io/InputStream;->close()V

    :next
    add-int/lit8 v7, v7, 0x1

    goto :loop

    :try_end_0
    .catch Ljava/lang/Exception; {:try_start_0 .. :try_end_0} :catch_0

    :return
    return-void

    :catch_0
    return-void
.end method
'@
[System.IO.File]::WriteAllText($helperPath, $helperSmali, $utf8NoBom)

$mainPath = Join-Path $targetDir "MainActivity.smali"
if (-not (Test-Path -LiteralPath $mainPath)) {
    throw "Missing MainActivity smali: $mainPath"
}

$mainText = Get-Content -LiteralPath $mainPath -Raw
if ($mainText -notmatch "Lxyz/aethersx2/android/BundledCheats;->install") {
    $pattern = "(?s)\.method public final onCreate\(Landroid/os/Bundle;\)V.*?if-nez p1, :cond_0.*?\r?\n\s*:cond_0\r?\n"
    $match = [regex]::Match($mainText, $pattern)
    if (-not $match.Success) {
        throw "Could not find MainActivity.onCreate native-init success label for bundled cheats install."
    }
    $insert = "`r`n    invoke-static {p0}, Lxyz/aethersx2/android/BundledCheats;->install(Landroid/content/Context;)V`r`n"
    $updated = $mainText.Insert($match.Index + $match.Length, $insert)
    [System.IO.File]::WriteAllText($mainPath, $updated, $utf8NoBom)
}

Write-Host "Bundled $($cheatFiles.Count) exact PNACH file(s) and patched startup seeding in $ProjectPath"
