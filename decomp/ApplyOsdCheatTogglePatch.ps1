param(
    [string]$ProjectPath = ""
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

$ProjectPath = (Resolve-Path -LiteralPath $ProjectPath).Path
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

function ConvertTo-Lf {
    param([string]$Text)
    return ($Text -replace "`r`n", "`n")
}

function Write-SmaliFile {
    param(
        [string]$Path,
        [string]$Text
    )

    [System.IO.File]::WriteAllText($Path, (ConvertTo-Lf -Text $Text), $utf8NoBom)
}

function Patch-PatchesMenuLabel {
    $path = Join-Path $ProjectPath "res\values\arrays.xml"
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing arrays resource: $path"
    }

    $text = [System.IO.File]::ReadAllText($path)
    $text = $text.Replace("<item>Edit Patches</item>", "<item>Toggle Cheat Codes</item>")
    $text = $text.Replace("<item>Edit / Toggle Cheats</item>", "<item>Toggle Cheat Codes</item>")
    [System.IO.File]::WriteAllText($path, $text, $utf8NoBom)
}

function Restore-OsdPatchStrings {
    $path = Join-Path $ProjectPath "res\values\strings.xml"
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing strings resource: $path"
    }

    $text = [System.IO.File]::ReadAllText($path)
    $text = $text.Replace('<string name="patches_menu_disable_patches">Disable Cheats</string>', '<string name="patches_menu_disable_patches">Disable Patches</string>')
    $text = $text.Replace('<string name="patches_menu_enable_patches">Enable Cheats</string>', '<string name="patches_menu_enable_patches">Enable Patches</string>')
    [System.IO.File]::WriteAllText($path, $text, $utf8NoBom)
}

function Write-OsdCheatMenuClasses {
    $targetDir = Join-Path $ProjectPath "smali\xyz\aethersx2\android"
    if (-not (Test-Path -LiteralPath $targetDir)) {
        throw "Missing smali package folder: $targetDir"
    }

    Write-SmaliFile -Path (Join-Path $targetDir "OsdCheatMenu.smali") -Text @'
.class public final Lxyz/aethersx2/android/OsdCheatMenu;
.super Ljava/lang/Object;
.source "OsdCheatMenu.java"


# direct methods
.method private constructor <init>()V
    .locals 0

    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    return-void
.end method

.method private static addCode(Ljava/util/ArrayList;Ljava/lang/String;IIZ)V
    .locals 2

    if-eqz p1, :cond_fallback

    invoke-virtual {p1}, Ljava/lang/String;->length()I

    move-result v0

    if-lez v0, :cond_fallback

    goto :goto_title

    :cond_fallback
    invoke-virtual {p0}, Ljava/util/ArrayList;->size()I

    move-result v0

    invoke-static {v0}, Lxyz/aethersx2/android/OsdCheatMenu;->makeFallbackTitle(I)Ljava/lang/String;

    move-result-object p1

    :goto_title
    new-instance v0, Lxyz/aethersx2/android/OsdCheatMenu$Code;

    invoke-direct {v0, p1, p2, p3, p4}, Lxyz/aethersx2/android/OsdCheatMenu$Code;-><init>(Ljava/lang/String;IIZ)V

    invoke-virtual {p0, v0}, Ljava/util/ArrayList;->add(Ljava/lang/Object;)Z

    return-void
.end method

.method private static cleanTitle(Ljava/lang/String;)Ljava/lang/String;
    .locals 3

    if-eqz p0, :cond_empty

    invoke-virtual {p0}, Ljava/lang/String;->trim()Ljava/lang/String;

    move-result-object v0

    const-string v1, "\\"

    const-string v2, " / "

    invoke-virtual {v0, v1, v2}, Ljava/lang/String;->replace(Ljava/lang/CharSequence;Ljava/lang/CharSequence;)Ljava/lang/String;

    move-result-object v0

    return-object v0

    :cond_empty
    const-string v0, ""

    return-object v0
.end method

.method private static disableLine(Ljava/lang/String;)Ljava/lang/String;
    .locals 2

    invoke-static {p0}, Lxyz/aethersx2/android/OsdCheatMenu;->isActivePatchLine(Ljava/lang/String;)Z

    move-result v0

    if-eqz v0, :cond_return

    new-instance v0, Ljava/lang/StringBuilder;

    invoke-direct {v0}, Ljava/lang/StringBuilder;-><init>()V

    const-string v1, "// "

    invoke-virtual {v0, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    invoke-virtual {p0}, Ljava/lang/String;->trim()Ljava/lang/String;

    move-result-object p0

    invoke-virtual {v0, p0}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    invoke-virtual {v0}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object p0

    :cond_return
    return-object p0
.end method

.method private static enableLine(Ljava/lang/String;)Ljava/lang/String;
    .locals 4

    if-eqz p0, :cond_return

    invoke-static {p0}, Lxyz/aethersx2/android/OsdCheatMenu;->isActivePatchLine(Ljava/lang/String;)Z

    move-result v0

    if-nez v0, :cond_return

    invoke-virtual {p0}, Ljava/lang/String;->trim()Ljava/lang/String;

    move-result-object v0

    const-string v1, "//"

    invoke-virtual {v0, v1}, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z

    move-result v1

    if-eqz v1, :cond_hash

    const/4 v1, 0x2

    invoke-virtual {v0, v1}, Ljava/lang/String;->substring(I)Ljava/lang/String;

    move-result-object v1

    invoke-virtual {v1}, Ljava/lang/String;->trim()Ljava/lang/String;

    move-result-object v1

    const-string v2, "patch="

    invoke-virtual {v1, v2}, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z

    move-result v2

    if-eqz v2, :cond_hash

    return-object v1

    :cond_hash
    const-string v1, "#"

    invoke-virtual {v0, v1}, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z

    move-result v1

    if-eqz v1, :cond_return

    const/4 v1, 0x1

    invoke-virtual {v0, v1}, Ljava/lang/String;->substring(I)Ljava/lang/String;

    move-result-object v1

    invoke-virtual {v1}, Ljava/lang/String;->trim()Ljava/lang/String;

    move-result-object v1

    const-string v2, "patch="

    invoke-virtual {v1, v2}, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z

    move-result v3

    if-eqz v3, :cond_return

    return-object v1

    :cond_return
    return-object p0
.end method

.method private static extractTitle(Ljava/lang/String;)Ljava/lang/String;
    .locals 7

    const/4 v0, 0x0

    if-eqz p0, :cond_return_null

    invoke-virtual {p0}, Ljava/lang/String;->trim()Ljava/lang/String;

    move-result-object v1

    invoke-virtual {v1}, Ljava/lang/String;->length()I

    move-result v2

    if-eqz v2, :cond_return_null

    const-string v2, "["

    invoke-virtual {v1, v2}, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z

    move-result v2

    if-eqz v2, :cond_comment_marker

    const-string v2, "]"

    invoke-virtual {v1, v2}, Ljava/lang/String;->indexOf(Ljava/lang/String;)I

    move-result v2

    if-lez v2, :cond_comment_marker

    const/4 v3, 0x1

    invoke-virtual {v1, v3, v2}, Ljava/lang/String;->substring(II)Ljava/lang/String;

    move-result-object v1

    invoke-static {v1}, Lxyz/aethersx2/android/OsdCheatMenu;->cleanTitle(Ljava/lang/String;)Ljava/lang/String;

    move-result-object v0

    return-object v0

    :cond_comment_marker
    const/4 v5, 0x0

    const-string v2, "//"

    invoke-virtual {v1, v2}, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z

    move-result v2

    if-eqz v2, :cond_hash_marker

    const/4 v2, 0x2

    invoke-virtual {v1, v2}, Ljava/lang/String;->substring(I)Ljava/lang/String;

    move-result-object v1

    invoke-virtual {v1}, Ljava/lang/String;->trim()Ljava/lang/String;

    move-result-object v1

    const/4 v5, 0x1

    goto :goto_after_marker

    :cond_hash_marker
    const-string v2, "#"

    invoke-virtual {v1, v2}, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z

    move-result v2

    if-eqz v2, :goto_after_marker

    const/4 v2, 0x1

    invoke-virtual {v1, v2}, Ljava/lang/String;->substring(I)Ljava/lang/String;

    move-result-object v1

    invoke-virtual {v1}, Ljava/lang/String;->trim()Ljava/lang/String;

    move-result-object v1

    const/4 v5, 0x1

    :goto_after_marker
    invoke-virtual {v1}, Ljava/lang/String;->toLowerCase()Ljava/lang/String;

    move-result-object v4

    const-string v2, "comment="

    invoke-virtual {v4, v2}, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z

    move-result v3

    if-eqz v3, :cond_not_comment

    const/16 v2, 0x8

    invoke-virtual {v1}, Ljava/lang/String;->length()I

    move-result v3

    if-le v3, v2, :cond_return_null

    invoke-virtual {v1, v2}, Ljava/lang/String;->substring(I)Ljava/lang/String;

    move-result-object v1

    invoke-static {v1}, Lxyz/aethersx2/android/OsdCheatMenu;->cleanTitle(Ljava/lang/String;)Ljava/lang/String;

    move-result-object v0

    return-object v0

    :cond_not_comment
    const-string v2, "gametitle="

    invoke-virtual {v4, v2}, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z

    move-result v3

    if-nez v3, :cond_return_null

    const-string v2, "file generated"

    invoke-virtual {v4, v2}, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z

    move-result v3

    if-nez v3, :cond_return_null

    const-string v2, "author="

    invoke-virtual {v4, v2}, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z

    move-result v3

    if-nez v3, :cond_return_null

    const-string v2, "description="

    invoke-virtual {v4, v2}, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z

    move-result v3

    if-nez v3, :cond_return_null

    const-string v2, "patch="

    invoke-virtual {v4, v2}, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z

    move-result v3

    if-nez v3, :cond_return_null

    if-eqz v5, :cond_return_null

    invoke-virtual {v1}, Ljava/lang/String;->length()I

    move-result v6

    if-eqz v6, :cond_return_null

    invoke-static {v1}, Lxyz/aethersx2/android/OsdCheatMenu;->cleanTitle(Ljava/lang/String;)Ljava/lang/String;

    move-result-object v0

    return-object v0

    :cond_return_null
    return-object v0
.end method

.method private static getPatchFile(Lxyz/aethersx2/android/EmulationActivity;)Ljava/io/File;
    .locals 7

    invoke-static {}, Lxyz/aethersx2/android/NativeLibrary;->getGameInfo()Ll6/l4;

    move-result-object v0

    if-eqz v0, :cond_no_path

    invoke-virtual {v0}, Ll6/l4;->a()Ljava/nio/file/Path;

    move-result-object v1

    if-eqz v1, :cond_external

    invoke-interface {v1}, Ljava/nio/file/Path;->toFile()Ljava/io/File;

    move-result-object v1

    invoke-virtual {v1}, Ljava/io/File;->isFile()Z

    move-result v2

    if-eqz v2, :cond_external

    invoke-static {v1}, Lxyz/aethersx2/android/OsdCheatMenu;->parseCodes(Ljava/io/File;)Ljava/util/ArrayList;

    move-result-object v2

    invoke-virtual {v2}, Ljava/util/ArrayList;->isEmpty()Z

    move-result v2

    if-nez v2, :cond_external

    return-object v1

    :cond_external
    iget-object v1, v0, Ll6/l4;->a:Ljava/lang/String;

    if-eqz v1, :cond_game_info_crc

    invoke-static {v1}, Lxyz/aethersx2/android/NativeLibrary;->getGameListEntry(Ljava/lang/String;)Lxyz/aethersx2/android/GameListEntry;

    move-result-object v6

    if-eqz v6, :cond_game_info_crc

    invoke-virtual {v6}, Lxyz/aethersx2/android/GameListEntry;->getCRC()I

    move-result v1

    if-nez v1, :cond_have_crc

    :cond_game_info_crc
    iget v1, v0, Ll6/l4;->e:I

    :cond_have_crc
    if-eqz v1, :cond_no_path

    const/4 v2, 0x0

    invoke-virtual {p0, v2}, Landroid/content/Context;->getExternalFilesDir(Ljava/lang/String;)Ljava/io/File;

    move-result-object p0

    if-eqz p0, :cond_no_path

    new-instance v2, Ljava/io/File;

    const-string v3, "cheats"

    invoke-direct {v2, p0, v3}, Ljava/io/File;-><init>(Ljava/io/File;Ljava/lang/String;)V

    const-string p0, "%08X.pnach"

    const/4 v3, 0x1

    new-array v4, v3, [Ljava/lang/Object;

    invoke-static {v1}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;

    move-result-object v1

    const/4 v5, 0x0

    aput-object v1, v4, v5

    invoke-static {p0, v4}, Ljava/lang/String;->format(Ljava/lang/String;[Ljava/lang/Object;)Ljava/lang/String;

    move-result-object p0

    new-instance v1, Ljava/io/File;

    invoke-direct {v1, v2, p0}, Ljava/io/File;-><init>(Ljava/io/File;Ljava/lang/String;)V

    invoke-virtual {v1}, Ljava/io/File;->isFile()Z

    move-result v4

    if-eqz v4, :cond_lowercase

    return-object v1

    :cond_lowercase
    invoke-virtual {p0}, Ljava/lang/String;->toLowerCase()Ljava/lang/String;

    move-result-object p0

    new-instance v1, Ljava/io/File;

    invoke-direct {v1, v2, p0}, Ljava/io/File;-><init>(Ljava/io/File;Ljava/lang/String;)V

    invoke-virtual {v1}, Ljava/io/File;->isFile()Z

    move-result p0

    if-eqz p0, :cond_no_path

    return-object v1

    :cond_no_path
    const/4 v0, 0x0

    return-object v0
.end method

.method private static isActivePatchLine(Ljava/lang/String;)Z
    .locals 2

    if-eqz p0, :cond_false

    invoke-virtual {p0}, Ljava/lang/String;->trim()Ljava/lang/String;

    move-result-object v0

    const-string v1, "patch="

    invoke-virtual {v0, v1}, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z

    move-result v0

    return v0

    :cond_false
    const/4 v0, 0x0

    return v0
.end method

.method private static isPatchLine(Ljava/lang/String;)Z
    .locals 4

    if-eqz p0, :cond_false

    invoke-virtual {p0}, Ljava/lang/String;->trim()Ljava/lang/String;

    move-result-object v0

    const-string v1, "patch="

    invoke-virtual {v0, v1}, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z

    move-result v2

    if-eqz v2, :cond_slash

    const/4 v0, 0x1

    return v0

    :cond_slash
    const-string v2, "//"

    invoke-virtual {v0, v2}, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z

    move-result v2

    if-eqz v2, :cond_hash

    const/4 v2, 0x2

    invoke-virtual {v0, v2}, Ljava/lang/String;->substring(I)Ljava/lang/String;

    move-result-object v2

    invoke-virtual {v2}, Ljava/lang/String;->trim()Ljava/lang/String;

    move-result-object v2

    invoke-virtual {v2, v1}, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z

    move-result v2

    if-eqz v2, :cond_hash

    const/4 v0, 0x1

    return v0

    :cond_hash
    const-string v2, "#"

    invoke-virtual {v0, v2}, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z

    move-result v2

    if-eqz v2, :cond_false

    const/4 v2, 0x1

    invoke-virtual {v0, v2}, Ljava/lang/String;->substring(I)Ljava/lang/String;

    move-result-object v3

    invoke-virtual {v3}, Ljava/lang/String;->trim()Ljava/lang/String;

    move-result-object v3

    invoke-virtual {v3, v1}, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z

    move-result v3

    if-eqz v3, :cond_false

    return v2

    :cond_false
    const/4 v0, 0x0

    return v0
.end method

.method private static makeFallbackTitle(I)Ljava/lang/String;
    .locals 2

    new-instance v0, Ljava/lang/StringBuilder;

    invoke-direct {v0}, Ljava/lang/StringBuilder;-><init>()V

    const-string v1, "Code "

    invoke-virtual {v0, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    add-int/lit8 p0, p0, 0x1

    invoke-virtual {v0, p0}, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;

    invoke-virtual {v0}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v0

    return-object v0
.end method

.method public static openEditor(Lxyz/aethersx2/android/EmulationActivity;)V
    .locals 4

    invoke-static {p0}, Lxyz/aethersx2/android/OsdCheatMenu;->getPatchFile(Lxyz/aethersx2/android/EmulationActivity;)Ljava/io/File;

    move-result-object v0

    if-nez v0, :cond_open

    const v0, 0x7f1001a0

    const/4 v1, 0x1

    invoke-static {p0, v0, v1}, Landroid/widget/Toast;->makeText(Landroid/content/Context;II)Landroid/widget/Toast;

    move-result-object p0

    invoke-virtual {p0}, Landroid/widget/Toast;->show()V

    return-void

    :cond_open
    invoke-virtual {p0}, Lxyz/aethersx2/android/EmulationActivity;->K()V

    new-instance v1, Landroid/content/Intent;

    const-class v2, Lxyz/aethersx2/android/FileEditorActivity;

    invoke-direct {v1, p0, v2}, Landroid/content/Intent;-><init>(Landroid/content/Context;Ljava/lang/Class;)V

    invoke-static {v0}, Landroid/net/Uri;->fromFile(Ljava/io/File;)Landroid/net/Uri;

    move-result-object v0

    invoke-virtual {v1, v0}, Landroid/content/Intent;->setData(Landroid/net/Uri;)Landroid/content/Intent;

    const/4 v0, 0x2

    invoke-virtual {p0, v1, v0}, Landroidx/activity/ComponentActivity;->startActivityForResult(Landroid/content/Intent;I)V

    return-void
.end method

.method public static parseCodes(Ljava/io/File;)Ljava/util/ArrayList;
    .locals 12

    new-instance v0, Ljava/util/ArrayList;

    invoke-direct {v0}, Ljava/util/ArrayList;-><init>()V

    :try_start_0
    invoke-virtual {p0}, Ljava/io/File;->toPath()Ljava/nio/file/Path;

    move-result-object v1

    invoke-static {v1}, Ljava/nio/file/Files;->readAllLines(Ljava/nio/file/Path;)Ljava/util/List;

    move-result-object v1

    const/4 v2, 0x0

    const/4 v3, 0x0

    const/4 v4, -0x1

    const/4 v5, 0x0

    const/4 v6, 0x0

    const/4 v7, -0x1

    :goto_loop
    invoke-interface {v1}, Ljava/util/List;->size()I

    move-result v8

    if-ge v2, v8, :cond_eof

    invoke-interface {v1, v2}, Ljava/util/List;->get(I)Ljava/lang/Object;

    move-result-object v8

    check-cast v8, Ljava/lang/String;

    invoke-static {v8}, Lxyz/aethersx2/android/OsdCheatMenu;->extractTitle(Ljava/lang/String;)Ljava/lang/String;

    move-result-object v9

    if-eqz v9, :cond_after_title

    if-eqz v5, :cond_set_title

    invoke-static {v0, v3, v4, v7, v6}, Lxyz/aethersx2/android/OsdCheatMenu;->addCode(Ljava/util/ArrayList;Ljava/lang/String;IIZ)V

    const/4 v5, 0x0

    const/4 v6, 0x0

    const/4 v7, -0x1

    :cond_set_title
    move-object v3, v9

    move v4, v2

    :cond_after_title
    invoke-static {v8}, Lxyz/aethersx2/android/OsdCheatMenu;->isPatchLine(Ljava/lang/String;)Z

    move-result v9

    if-eqz v9, :cond_maybe_blank

    if-nez v3, :cond_have_title

    invoke-virtual {v0}, Ljava/util/ArrayList;->size()I

    move-result v9

    invoke-static {v9}, Lxyz/aethersx2/android/OsdCheatMenu;->makeFallbackTitle(I)Ljava/lang/String;

    move-result-object v3

    move v4, v2

    :cond_have_title
    if-gez v4, :cond_start_ok

    move v4, v2

    :cond_start_ok
    const/4 v5, 0x1

    move v7, v2

    invoke-static {v8}, Lxyz/aethersx2/android/OsdCheatMenu;->isActivePatchLine(Ljava/lang/String;)Z

    move-result v9

    if-eqz v9, :cond_after_line

    const/4 v6, 0x1

    goto :cond_after_line

    :cond_maybe_blank
    invoke-virtual {v8}, Ljava/lang/String;->trim()Ljava/lang/String;

    move-result-object v9

    invoke-virtual {v9}, Ljava/lang/String;->length()I

    move-result v9

    if-nez v9, :cond_after_line

    if-eqz v5, :cond_clear_pending

    invoke-static {v0, v3, v4, v7, v6}, Lxyz/aethersx2/android/OsdCheatMenu;->addCode(Ljava/util/ArrayList;Ljava/lang/String;IIZ)V

    :cond_clear_pending
    const/4 v3, 0x0

    const/4 v4, -0x1

    const/4 v5, 0x0

    const/4 v6, 0x0

    const/4 v7, -0x1

    :cond_after_line
    add-int/lit8 v2, v2, 0x1

    goto :goto_loop

    :cond_eof
    if-eqz v5, :cond_return

    invoke-static {v0, v3, v4, v7, v6}, Lxyz/aethersx2/android/OsdCheatMenu;->addCode(Ljava/util/ArrayList;Ljava/lang/String;IIZ)V

    :cond_return
    :try_end_0
    .catch Ljava/lang/Exception; {:try_start_0 .. :try_end_0} :catch_0

    return-object v0

    :catch_0
    return-object v0
.end method

.method public static saveStates(Ljava/io/File;Ljava/util/ArrayList;[Z)V
    .locals 11

    invoke-virtual {p0}, Ljava/io/File;->toPath()Ljava/nio/file/Path;

    move-result-object v0

    invoke-static {v0}, Ljava/nio/file/Files;->readAllLines(Ljava/nio/file/Path;)Ljava/util/List;

    move-result-object v1

    new-instance v2, Ljava/util/ArrayList;

    invoke-direct {v2, v1}, Ljava/util/ArrayList;-><init>(Ljava/util/Collection;)V

    const/4 v3, 0x0

    :goto_code_loop
    invoke-virtual {p1}, Ljava/util/ArrayList;->size()I

    move-result v4

    if-ge v3, v4, :cond_write

    invoke-virtual {p1, v3}, Ljava/util/ArrayList;->get(I)Ljava/lang/Object;

    move-result-object v5

    check-cast v5, Lxyz/aethersx2/android/OsdCheatMenu$Code;

    aget-boolean v6, p2, v3

    iget v7, v5, Lxyz/aethersx2/android/OsdCheatMenu$Code;->b:I

    iget v8, v5, Lxyz/aethersx2/android/OsdCheatMenu$Code;->c:I

    :goto_line_loop
    if-le v7, v8, :cond_line

    add-int/lit8 v3, v3, 0x1

    goto :goto_code_loop

    :cond_line
    invoke-virtual {v2, v7}, Ljava/util/ArrayList;->get(I)Ljava/lang/Object;

    move-result-object v9

    check-cast v9, Ljava/lang/String;

    invoke-static {v9}, Lxyz/aethersx2/android/OsdCheatMenu;->isPatchLine(Ljava/lang/String;)Z

    move-result v10

    if-eqz v10, :cond_next_line

    if-eqz v6, :cond_disable

    invoke-static {v9}, Lxyz/aethersx2/android/OsdCheatMenu;->enableLine(Ljava/lang/String;)Ljava/lang/String;

    move-result-object v9

    goto :cond_set_line

    :cond_disable
    invoke-static {v9}, Lxyz/aethersx2/android/OsdCheatMenu;->disableLine(Ljava/lang/String;)Ljava/lang/String;

    move-result-object v9

    :cond_set_line
    invoke-virtual {v2, v7, v9}, Ljava/util/ArrayList;->set(ILjava/lang/Object;)Ljava/lang/Object;

    :cond_next_line
    add-int/lit8 v7, v7, 0x1

    goto :goto_line_loop

    :cond_write
    const-string v3, "pnach"

    const-string v4, ".tmp"

    invoke-virtual {p0}, Ljava/io/File;->getParentFile()Ljava/io/File;

    move-result-object v5

    invoke-static {v3, v4, v5}, Ljava/io/File;->createTempFile(Ljava/lang/String;Ljava/lang/String;Ljava/io/File;)Ljava/io/File;

    move-result-object v3

    invoke-virtual {v3}, Ljava/io/File;->toPath()Ljava/nio/file/Path;

    move-result-object v4

    const/4 v5, 0x0

    new-array v5, v5, [Ljava/nio/file/OpenOption;

    invoke-static {v4, v2, v5}, Ljava/nio/file/Files;->write(Ljava/nio/file/Path;Ljava/lang/Iterable;[Ljava/nio/file/OpenOption;)Ljava/nio/file/Path;

    invoke-virtual {p0}, Ljava/io/File;->delete()Z

    move-result v4

    if-nez v4, :cond_rename

    new-instance p0, Ljava/io/IOException;

    const-string p1, "Could not replace cheat file"

    invoke-direct {p0, p1}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p0

    :cond_rename
    invoke-virtual {v3, p0}, Ljava/io/File;->renameTo(Ljava/io/File;)Z

    move-result p0

    if-eqz p0, :cond_rename_failed

    return-void

    :cond_rename_failed
    new-instance p0, Ljava/io/IOException;

    const-string p1, "Could not rename cheat file"

    invoke-direct {p0, p1}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p0
.end method

.method public static show(Lxyz/aethersx2/android/EmulationActivity;)V
    .locals 8

    invoke-static {p0}, Lxyz/aethersx2/android/OsdCheatMenu;->getPatchFile(Lxyz/aethersx2/android/EmulationActivity;)Ljava/io/File;

    move-result-object v0

    if-nez v0, :cond_has_file

    const v0, 0x7f1001a0

    const/4 v1, 0x1

    invoke-static {p0, v0, v1}, Landroid/widget/Toast;->makeText(Landroid/content/Context;II)Landroid/widget/Toast;

    move-result-object p0

    invoke-virtual {p0}, Landroid/widget/Toast;->show()V

    return-void

    :cond_has_file
    invoke-static {v0}, Lxyz/aethersx2/android/OsdCheatMenu;->parseCodes(Ljava/io/File;)Ljava/util/ArrayList;

    move-result-object v1

    invoke-virtual {v1}, Ljava/util/ArrayList;->size()I

    move-result v2

    if-nez v2, :cond_has_codes

    invoke-static {p0, v0}, Lxyz/aethersx2/android/OsdCheatMenu;->showNoCodes(Lxyz/aethersx2/android/EmulationActivity;Ljava/io/File;)V

    return-void

    :cond_has_codes
    new-array v3, v2, [Ljava/lang/CharSequence;

    new-array v4, v2, [Z

    const/4 v5, 0x0

    :goto_item_loop
    if-ge v5, v2, :cond_build

    invoke-virtual {v1, v5}, Ljava/util/ArrayList;->get(I)Ljava/lang/Object;

    move-result-object v6

    check-cast v6, Lxyz/aethersx2/android/OsdCheatMenu$Code;

    iget-object v7, v6, Lxyz/aethersx2/android/OsdCheatMenu$Code;->a:Ljava/lang/String;

    aput-object v7, v3, v5

    iget-boolean v7, v6, Lxyz/aethersx2/android/OsdCheatMenu$Code;->d:Z

    aput-boolean v7, v4, v5

    add-int/lit8 v5, v5, 0x1

    goto :goto_item_loop

    :cond_build
    new-instance v5, Landroidx/appcompat/app/d$a;

    invoke-direct {v5, p0}, Landroidx/appcompat/app/d$a;-><init>(Landroid/content/Context;)V

    const v2, 0x7f1000ba

    invoke-virtual {v5, v2}, Landroidx/appcompat/app/d$a;->j(I)Landroidx/appcompat/app/d$a;

    new-instance v6, Lxyz/aethersx2/android/OsdCheatMenu$ChoiceListener;

    invoke-direct {v6, v4}, Lxyz/aethersx2/android/OsdCheatMenu$ChoiceListener;-><init>([Z)V

    invoke-virtual {v5, v3, v4, v6}, Landroidx/appcompat/app/d$a;->d([Ljava/lang/CharSequence;[ZLandroid/content/DialogInterface$OnMultiChoiceClickListener;)Landroidx/appcompat/app/d$a;

    const-string v3, "Apply"

    new-instance v6, Lxyz/aethersx2/android/OsdCheatMenu$ApplyListener;

    invoke-direct {v6, p0, v0, v1, v4}, Lxyz/aethersx2/android/OsdCheatMenu$ApplyListener;-><init>(Lxyz/aethersx2/android/EmulationActivity;Ljava/io/File;Ljava/util/ArrayList;[Z)V

    invoke-virtual {v5, v3, v6}, Landroidx/appcompat/app/d$a;->h(Ljava/lang/CharSequence;Landroid/content/DialogInterface$OnClickListener;)Landroidx/appcompat/app/d$a;

    const v0, 0x7f100097

    const/4 v1, 0x0

    invoke-virtual {v5, v0, v1}, Landroidx/appcompat/app/d$a;->e(ILandroid/content/DialogInterface$OnClickListener;)Landroidx/appcompat/app/d$a;

    iget-object v0, v5, Landroidx/appcompat/app/d$a;->a:Landroidx/appcompat/app/AlertController$b;

    const-string v1, "Deselect All"

    iput-object v1, v0, Landroidx/appcompat/app/AlertController$b;->k:Ljava/lang/CharSequence;

    const/4 v1, 0x0

    iput-object v1, v0, Landroidx/appcompat/app/AlertController$b;->l:Landroid/content/DialogInterface$OnClickListener;

    new-instance v1, Ll6/q3;

    invoke-direct {v1, p0}, Ll6/q3;-><init>(Lxyz/aethersx2/android/EmulationActivity;)V

    iput-object v1, v0, Landroidx/appcompat/app/AlertController$b;->n:Landroid/content/DialogInterface$OnDismissListener;

    invoke-virtual {v5}, Landroidx/appcompat/app/d$a;->a()Landroidx/appcompat/app/d;

    move-result-object p0

    invoke-virtual {p0}, Landroid/app/Dialog;->show()V

    iget-object v0, p0, Landroidx/appcompat/app/d;->k:Landroidx/appcompat/app/AlertController;

    iget-object v1, v0, Landroidx/appcompat/app/AlertController;->s:Landroid/widget/Button;

    if-eqz v1, :cond_return

    iget-object v0, v0, Landroidx/appcompat/app/AlertController;->g:Landroidx/appcompat/app/AlertController$RecycleListView;

    if-eqz v0, :cond_return

    new-instance v2, Lxyz/aethersx2/android/OsdCheatMenu$DeselectAllListener;

    invoke-direct {v2, v0, v4}, Lxyz/aethersx2/android/OsdCheatMenu$DeselectAllListener;-><init>(Landroid/widget/AbsListView;[Z)V

    invoke-virtual {v1, v2}, Landroid/view/View;->setOnClickListener(Landroid/view/View$OnClickListener;)V

    :cond_return

    return-void
.end method

.method private static showNoCodes(Lxyz/aethersx2/android/EmulationActivity;Ljava/io/File;)V
    .locals 4

    new-instance v0, Landroidx/appcompat/app/d$a;

    invoke-direct {v0, p0}, Landroidx/appcompat/app/d$a;-><init>(Landroid/content/Context;)V

    const p1, 0x7f1000ba

    invoke-virtual {v0, p1}, Landroidx/appcompat/app/d$a;->j(I)Landroidx/appcompat/app/d$a;

    iget-object p1, v0, Landroidx/appcompat/app/d$a;->a:Landroidx/appcompat/app/AlertController$b;

    const-string v1, "No cheat code blocks found in this .pnach."

    iput-object v1, p1, Landroidx/appcompat/app/AlertController$b;->f:Ljava/lang/CharSequence;

    const-string v1, "Edit .pnach"

    new-instance v2, Lxyz/aethersx2/android/OsdCheatMenu$EditListener;

    invoke-direct {v2, p0}, Lxyz/aethersx2/android/OsdCheatMenu$EditListener;-><init>(Lxyz/aethersx2/android/EmulationActivity;)V

    invoke-virtual {v0, v1, v2}, Landroidx/appcompat/app/d$a;->h(Ljava/lang/CharSequence;Landroid/content/DialogInterface$OnClickListener;)Landroidx/appcompat/app/d$a;

    const v1, 0x7f100097

    const/4 v2, 0x0

    invoke-virtual {v0, v1, v2}, Landroidx/appcompat/app/d$a;->e(ILandroid/content/DialogInterface$OnClickListener;)Landroidx/appcompat/app/d$a;

    new-instance v1, Ll6/q3;

    invoke-direct {v1, p0}, Ll6/q3;-><init>(Lxyz/aethersx2/android/EmulationActivity;)V

    iput-object v1, p1, Landroidx/appcompat/app/AlertController$b;->n:Landroid/content/DialogInterface$OnDismissListener;

    invoke-virtual {v0}, Landroidx/appcompat/app/d$a;->a()Landroidx/appcompat/app/d;

    move-result-object p0

    invoke-virtual {p0}, Landroid/app/Dialog;->show()V

    return-void
.end method
'@

    Write-SmaliFile -Path (Join-Path $targetDir "OsdCheatMenu`$ApplyListener.smali") -Text @'
.class public final Lxyz/aethersx2/android/OsdCheatMenu$ApplyListener;
.super Ljava/lang/Object;
.source "OsdCheatMenu.java"

# interfaces
.implements Landroid/content/DialogInterface$OnClickListener;


# annotations
.annotation system Ldalvik/annotation/EnclosingClass;
    value = Lxyz/aethersx2/android/OsdCheatMenu;
.end annotation

.annotation system Ldalvik/annotation/InnerClass;
    accessFlags = 0x19
    name = "ApplyListener"
.end annotation


# instance fields
.field public final a:Lxyz/aethersx2/android/EmulationActivity;

.field public final b:Ljava/io/File;

.field public final c:Ljava/util/ArrayList;

.field public final d:[Z


# direct methods
.method public constructor <init>(Lxyz/aethersx2/android/EmulationActivity;Ljava/io/File;Ljava/util/ArrayList;[Z)V
    .locals 0

    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    iput-object p1, p0, Lxyz/aethersx2/android/OsdCheatMenu$ApplyListener;->a:Lxyz/aethersx2/android/EmulationActivity;

    iput-object p2, p0, Lxyz/aethersx2/android/OsdCheatMenu$ApplyListener;->b:Ljava/io/File;

    iput-object p3, p0, Lxyz/aethersx2/android/OsdCheatMenu$ApplyListener;->c:Ljava/util/ArrayList;

    iput-object p4, p0, Lxyz/aethersx2/android/OsdCheatMenu$ApplyListener;->d:[Z

    return-void
.end method


# virtual methods
.method public final onClick(Landroid/content/DialogInterface;I)V
    .locals 4

    :try_start_0
    iget-object p1, p0, Lxyz/aethersx2/android/OsdCheatMenu$ApplyListener;->b:Ljava/io/File;

    iget-object p2, p0, Lxyz/aethersx2/android/OsdCheatMenu$ApplyListener;->c:Ljava/util/ArrayList;

    iget-object v0, p0, Lxyz/aethersx2/android/OsdCheatMenu$ApplyListener;->d:[Z

    invoke-static {p1, p2, v0}, Lxyz/aethersx2/android/OsdCheatMenu;->saveStates(Ljava/io/File;Ljava/util/ArrayList;[Z)V
    :try_end_0
    .catch Ljava/lang/Exception; {:try_start_0 .. :try_end_0} :catch_0

    :try_start_1
    invoke-static {}, Lxyz/aethersx2/android/NativeLibrary;->reloadPatches()V
    :try_end_1
    .catch Ljava/lang/Exception; {:try_start_1 .. :try_end_1} :catch_1

    :goto_success

    iget-object p1, p0, Lxyz/aethersx2/android/OsdCheatMenu$ApplyListener;->a:Lxyz/aethersx2/android/EmulationActivity;

    const-string p2, "Cheat codes updated"

    const/4 v0, 0x0

    invoke-static {p1, p2, v0}, Landroid/widget/Toast;->makeText(Landroid/content/Context;Ljava/lang/CharSequence;I)Landroid/widget/Toast;

    move-result-object p1

    invoke-virtual {p1}, Landroid/widget/Toast;->show()V

    return-void

    :catch_1
    goto :goto_success

    :catch_0
    iget-object p1, p0, Lxyz/aethersx2/android/OsdCheatMenu$ApplyListener;->a:Lxyz/aethersx2/android/EmulationActivity;

    const-string p2, "Could not save cheat codes"

    const/4 v0, 0x1

    invoke-static {p1, p2, v0}, Landroid/widget/Toast;->makeText(Landroid/content/Context;Ljava/lang/CharSequence;I)Landroid/widget/Toast;

    move-result-object p1

    invoke-virtual {p1}, Landroid/widget/Toast;->show()V

    return-void
.end method
'@

    Write-SmaliFile -Path (Join-Path $targetDir "OsdCheatMenu`$ChoiceListener.smali") -Text @'
.class public final Lxyz/aethersx2/android/OsdCheatMenu$ChoiceListener;
.super Ljava/lang/Object;
.source "OsdCheatMenu.java"

# interfaces
.implements Landroid/content/DialogInterface$OnMultiChoiceClickListener;


# annotations
.annotation system Ldalvik/annotation/EnclosingClass;
    value = Lxyz/aethersx2/android/OsdCheatMenu;
.end annotation

.annotation system Ldalvik/annotation/InnerClass;
    accessFlags = 0x19
    name = "ChoiceListener"
.end annotation


# instance fields
.field public final a:[Z


# direct methods
.method public constructor <init>([Z)V
    .locals 0

    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    iput-object p1, p0, Lxyz/aethersx2/android/OsdCheatMenu$ChoiceListener;->a:[Z

    return-void
.end method


# virtual methods
.method public final onClick(Landroid/content/DialogInterface;IZ)V
    .locals 1

    iget-object p1, p0, Lxyz/aethersx2/android/OsdCheatMenu$ChoiceListener;->a:[Z

    aput-boolean p3, p1, p2

    return-void
.end method
'@

    Write-SmaliFile -Path (Join-Path $targetDir "OsdCheatMenu`$Code.smali") -Text @'
.class public final Lxyz/aethersx2/android/OsdCheatMenu$Code;
.super Ljava/lang/Object;
.source "OsdCheatMenu.java"


# annotations
.annotation system Ldalvik/annotation/EnclosingClass;
    value = Lxyz/aethersx2/android/OsdCheatMenu;
.end annotation

.annotation system Ldalvik/annotation/InnerClass;
    accessFlags = 0x19
    name = "Code"
.end annotation


# instance fields
.field public final a:Ljava/lang/String;

.field public final b:I

.field public final c:I

.field public final d:Z


# direct methods
.method public constructor <init>(Ljava/lang/String;IIZ)V
    .locals 0

    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    iput-object p1, p0, Lxyz/aethersx2/android/OsdCheatMenu$Code;->a:Ljava/lang/String;

    iput p2, p0, Lxyz/aethersx2/android/OsdCheatMenu$Code;->b:I

    iput p3, p0, Lxyz/aethersx2/android/OsdCheatMenu$Code;->c:I

    iput-boolean p4, p0, Lxyz/aethersx2/android/OsdCheatMenu$Code;->d:Z

    return-void
.end method
'@

    Write-SmaliFile -Path (Join-Path $targetDir "OsdCheatMenu`$DeselectAllListener.smali") -Text @'
.class public final Lxyz/aethersx2/android/OsdCheatMenu$DeselectAllListener;
.super Ljava/lang/Object;
.source "OsdCheatMenu.java"

# interfaces
.implements Landroid/view/View$OnClickListener;


# annotations
.annotation system Ldalvik/annotation/EnclosingClass;
    value = Lxyz/aethersx2/android/OsdCheatMenu;
.end annotation

.annotation system Ldalvik/annotation/InnerClass;
    accessFlags = 0x19
    name = "DeselectAllListener"
.end annotation


# instance fields
.field public final a:Landroid/widget/AbsListView;

.field public final b:[Z


# direct methods
.method public constructor <init>(Landroid/widget/AbsListView;[Z)V
    .locals 0

    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    iput-object p1, p0, Lxyz/aethersx2/android/OsdCheatMenu$DeselectAllListener;->a:Landroid/widget/AbsListView;

    iput-object p2, p0, Lxyz/aethersx2/android/OsdCheatMenu$DeselectAllListener;->b:[Z

    return-void
.end method


# virtual methods
.method public final onClick(Landroid/view/View;)V
    .locals 4

    const/4 p1, 0x0

    :goto_loop
    iget-object v0, p0, Lxyz/aethersx2/android/OsdCheatMenu$DeselectAllListener;->b:[Z

    array-length v1, v0

    if-ge p1, v1, :cond_done

    const/4 v1, 0x0

    aput-boolean v1, v0, p1

    iget-object v0, p0, Lxyz/aethersx2/android/OsdCheatMenu$DeselectAllListener;->a:Landroid/widget/AbsListView;

    invoke-virtual {v0, p1, v1}, Landroid/widget/AbsListView;->setItemChecked(IZ)V

    add-int/lit8 p1, p1, 0x1

    goto :goto_loop

    :cond_done
    iget-object p1, p0, Lxyz/aethersx2/android/OsdCheatMenu$DeselectAllListener;->a:Landroid/widget/AbsListView;

    invoke-virtual {p1}, Landroid/widget/AbsListView;->invalidateViews()V

    return-void
.end method
'@

    Write-SmaliFile -Path (Join-Path $targetDir "OsdCheatMenu`$EditListener.smali") -Text @'
.class public final Lxyz/aethersx2/android/OsdCheatMenu$EditListener;
.super Ljava/lang/Object;
.source "OsdCheatMenu.java"

# interfaces
.implements Landroid/content/DialogInterface$OnClickListener;


# annotations
.annotation system Ldalvik/annotation/EnclosingClass;
    value = Lxyz/aethersx2/android/OsdCheatMenu;
.end annotation

.annotation system Ldalvik/annotation/InnerClass;
    accessFlags = 0x19
    name = "EditListener"
.end annotation


# instance fields
.field public final a:Lxyz/aethersx2/android/EmulationActivity;


# direct methods
.method public constructor <init>(Lxyz/aethersx2/android/EmulationActivity;)V
    .locals 0

    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    iput-object p1, p0, Lxyz/aethersx2/android/OsdCheatMenu$EditListener;->a:Lxyz/aethersx2/android/EmulationActivity;

    return-void
.end method


# virtual methods
.method public final onClick(Landroid/content/DialogInterface;I)V
    .locals 0

    iget-object p1, p0, Lxyz/aethersx2/android/OsdCheatMenu$EditListener;->a:Lxyz/aethersx2/android/EmulationActivity;

    invoke-static {p1}, Lxyz/aethersx2/android/OsdCheatMenu;->openEditor(Lxyz/aethersx2/android/EmulationActivity;)V

    return-void
.end method
'@

    $oldToggleListener = Join-Path $targetDir "OsdCheatMenu`$ToggleListener.smali"
    if (Test-Path -LiteralPath $oldToggleListener) {
        Remove-Item -LiteralPath $oldToggleListener -Force
    }
}

function Patch-OsdMenuHandler {
    $path = Join-Path $ProjectPath "smali\l6\m3.smali"
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing OSD patch menu handler: $path"
    }

    $text = ConvertTo-Lf -Text ([System.IO.File]::ReadAllText($path))
    if ($text.Contains("Lxyz/aethersx2/android/OsdCheatMenu;->show")) {
        [System.IO.File]::WriteAllText($path, $text, $utf8NoBom)
        return
    }

    $pattern = '(?s)    \.line 13\n    :cond_3\n.*?    goto :goto_1\n\n(?=    \.line 20\n    :cond_6)'
    $replacement = @'
    .line 13
    :cond_3
    invoke-static {p1}, Lxyz/aethersx2/android/OsdCheatMenu;->show(Lxyz/aethersx2/android/EmulationActivity;)V

    goto :goto_1

'@

    $patched = [System.Text.RegularExpressions.Regex]::Replace($text, $pattern, (ConvertTo-Lf -Text $replacement), 1)
    if ($patched -eq $text) {
        throw "Could not patch OSD Edit Patches handler."
    }

    [System.IO.File]::WriteAllText($path, $patched, $utf8NoBom)
}

Patch-PatchesMenuLabel
Restore-OsdPatchStrings
Write-OsdCheatMenuClasses
Patch-OsdMenuHandler

Write-Host "OSD per-code cheat toggle dialog updated in $ProjectPath"
