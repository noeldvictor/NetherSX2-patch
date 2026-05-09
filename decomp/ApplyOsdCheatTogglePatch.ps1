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
    $text = $text.Replace("<item>Edit Patches</item>", "<item>Edit / Toggle Cheats</item>")
    [System.IO.File]::WriteAllText($path, $text, $utf8NoBom)
}

function Patch-OsdStrings {
    $path = Join-Path $ProjectPath "res\values\strings.xml"
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing strings resource: $path"
    }

    $text = [System.IO.File]::ReadAllText($path)
    $text = $text.Replace('<string name="patches_menu_disable_patches">Disable Patches</string>', '<string name="patches_menu_disable_patches">Disable Cheats</string>')
    $text = $text.Replace('<string name="patches_menu_enable_patches">Enable Patches</string>', '<string name="patches_menu_enable_patches">Enable Cheats</string>')
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

.method public static openEditor(Lxyz/aethersx2/android/EmulationActivity;)V
    .locals 4

    invoke-static {}, Lxyz/aethersx2/android/NativeLibrary;->getGameInfo()Ll6/l4;

    move-result-object v0

    if-eqz v0, :cond_no_path

    invoke-virtual {v0}, Ll6/l4;->a()Ljava/nio/file/Path;

    move-result-object v0

    goto :goto_path

    :cond_no_path
    const/4 v0, 0x0

    :goto_path
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

    invoke-interface {v0}, Ljava/nio/file/Path;->toFile()Ljava/io/File;

    move-result-object v0

    invoke-static {v0}, Landroid/net/Uri;->fromFile(Ljava/io/File;)Landroid/net/Uri;

    move-result-object v0

    invoke-virtual {v1, v0}, Landroid/content/Intent;->setData(Landroid/net/Uri;)Landroid/content/Intent;

    const/4 v0, 0x2

    invoke-virtual {p0, v1, v0}, Landroidx/activity/ComponentActivity;->startActivityForResult(Landroid/content/Intent;I)V

    return-void
.end method

.method public static show(Lxyz/aethersx2/android/EmulationActivity;)V
    .locals 7

    new-instance v0, Landroid/widget/LinearLayout;

    invoke-direct {v0, p0}, Landroid/widget/LinearLayout;-><init>(Landroid/content/Context;)V

    const/4 v1, 0x1

    invoke-virtual {v0, v1}, Landroid/widget/LinearLayout;->setOrientation(I)V

    const/16 v2, 0x30

    const/16 v3, 0x18

    invoke-virtual {v0, v2, v3, v2, v3}, Landroid/view/View;->setPadding(IIII)V

    new-instance v2, Landroid/widget/Switch;

    invoke-direct {v2, p0}, Landroid/widget/Switch;-><init>(Landroid/content/Context;)V

    const-string v3, "Enable Cheats"

    invoke-virtual {v2, v3}, Landroid/widget/TextView;->setText(Ljava/lang/CharSequence;)V

    const/high16 v3, 0x41800000    # 16.0f

    invoke-virtual {v2, v3}, Landroid/widget/TextView;->setTextSize(F)V

    invoke-virtual {v2, v1}, Landroid/widget/Switch;->setShowText(Z)V

    const-string v3, "ON"

    invoke-virtual {v2, v3}, Landroid/widget/Switch;->setTextOn(Ljava/lang/CharSequence;)V

    const-string v3, "OFF"

    invoke-virtual {v2, v3}, Landroid/widget/Switch;->setTextOff(Ljava/lang/CharSequence;)V

    iget-object v3, p0, Lxyz/aethersx2/android/EmulationActivity;->E:Landroid/content/SharedPreferences;

    const-string v4, "EmuCore/EnableCheats"

    const/4 v5, 0x0

    invoke-interface {v3, v4, v5}, Landroid/content/SharedPreferences;->getBoolean(Ljava/lang/String;Z)Z

    move-result v3

    invoke-virtual {v2, v3}, Landroid/widget/CompoundButton;->setChecked(Z)V

    new-instance v3, Lxyz/aethersx2/android/OsdCheatMenu$ToggleListener;

    invoke-direct {v3, p0}, Lxyz/aethersx2/android/OsdCheatMenu$ToggleListener;-><init>(Lxyz/aethersx2/android/EmulationActivity;)V

    invoke-virtual {v2, v3}, Landroid/widget/CompoundButton;->setOnCheckedChangeListener(Landroid/widget/CompoundButton$OnCheckedChangeListener;)V

    invoke-virtual {v0, v2}, Landroid/view/ViewGroup;->addView(Landroid/view/View;)V

    new-instance v2, Landroid/widget/TextView;

    invoke-direct {v2, p0}, Landroid/widget/TextView;-><init>(Landroid/content/Context;)V

    const-string v3, "Turn cheat patch files on or off without opening the text editor."

    invoke-virtual {v2, v3}, Landroid/widget/TextView;->setText(Ljava/lang/CharSequence;)V

    const/16 v3, 0xc

    invoke-virtual {v2, v5, v3, v5, v5}, Landroid/view/View;->setPadding(IIII)V

    invoke-virtual {v0, v2}, Landroid/view/ViewGroup;->addView(Landroid/view/View;)V

    new-instance v2, Landroidx/appcompat/app/d$a;

    invoke-direct {v2, p0}, Landroidx/appcompat/app/d$a;-><init>(Landroid/content/Context;)V

    const v3, 0x7f1000ba

    invoke-virtual {v2, v3}, Landroidx/appcompat/app/d$a;->j(I)Landroidx/appcompat/app/d$a;

    iget-object v3, v2, Landroidx/appcompat/app/d$a;->a:Landroidx/appcompat/app/AlertController$b;

    iput-object v0, v3, Landroidx/appcompat/app/AlertController$b;->s:Landroid/view/View;

    new-instance v0, Ll6/q3;

    invoke-direct {v0, p0}, Ll6/q3;-><init>(Lxyz/aethersx2/android/EmulationActivity;)V

    iput-object v0, v3, Landroidx/appcompat/app/AlertController$b;->n:Landroid/content/DialogInterface$OnDismissListener;

    const-string v0, "Edit .pnach"

    new-instance v3, Lxyz/aethersx2/android/OsdCheatMenu$EditListener;

    invoke-direct {v3, p0}, Lxyz/aethersx2/android/OsdCheatMenu$EditListener;-><init>(Lxyz/aethersx2/android/EmulationActivity;)V

    invoke-virtual {v2, v0, v3}, Landroidx/appcompat/app/d$a;->h(Ljava/lang/CharSequence;Landroid/content/DialogInterface$OnClickListener;)Landroidx/appcompat/app/d$a;

    const v0, 0x7f100097

    const/4 v3, 0x0

    invoke-virtual {v2, v0, v3}, Landroidx/appcompat/app/d$a;->e(ILandroid/content/DialogInterface$OnClickListener;)Landroidx/appcompat/app/d$a;

    invoke-virtual {v2}, Landroidx/appcompat/app/d$a;->a()Landroidx/appcompat/app/d;

    move-result-object p0

    invoke-virtual {p0}, Landroid/app/Dialog;->show()V

    return-void
.end method
'@

    Write-SmaliFile -Path (Join-Path $targetDir "OsdCheatMenu`$ToggleListener.smali") -Text @'
.class public final Lxyz/aethersx2/android/OsdCheatMenu$ToggleListener;
.super Ljava/lang/Object;
.source "OsdCheatMenu.java"

# interfaces
.implements Landroid/widget/CompoundButton$OnCheckedChangeListener;


# annotations
.annotation system Ldalvik/annotation/EnclosingClass;
    value = Lxyz/aethersx2/android/OsdCheatMenu;
.end annotation

.annotation system Ldalvik/annotation/InnerClass;
    accessFlags = 0x19
    name = "ToggleListener"
.end annotation


# instance fields
.field public final a:Lxyz/aethersx2/android/EmulationActivity;


# direct methods
.method public constructor <init>(Lxyz/aethersx2/android/EmulationActivity;)V
    .locals 0

    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    iput-object p1, p0, Lxyz/aethersx2/android/OsdCheatMenu$ToggleListener;->a:Lxyz/aethersx2/android/EmulationActivity;

    return-void
.end method


# virtual methods
.method public final onCheckedChanged(Landroid/widget/CompoundButton;Z)V
    .locals 2

    iget-object p1, p0, Lxyz/aethersx2/android/OsdCheatMenu$ToggleListener;->a:Lxyz/aethersx2/android/EmulationActivity;

    iget-object p1, p1, Lxyz/aethersx2/android/EmulationActivity;->E:Landroid/content/SharedPreferences;

    invoke-interface {p1}, Landroid/content/SharedPreferences;->edit()Landroid/content/SharedPreferences$Editor;

    move-result-object p1

    const-string v0, "EmuCore/EnableCheats"

    invoke-interface {p1, v0, p2}, Landroid/content/SharedPreferences$Editor;->putBoolean(Ljava/lang/String;Z)Landroid/content/SharedPreferences$Editor;

    invoke-interface {p1}, Landroid/content/SharedPreferences$Editor;->apply()V

    invoke-static {}, Lxyz/aethersx2/android/NativeLibrary;->applySettings()V

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
Patch-OsdStrings
Write-OsdCheatMenuClasses
Patch-OsdMenuHandler

Write-Host "OSD cheat toggle dialog updated in $ProjectPath"
