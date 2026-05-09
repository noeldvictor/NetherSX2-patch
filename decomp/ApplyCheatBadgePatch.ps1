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

$ProjectPath = (Resolve-Path -LiteralPath $ProjectPath).Path

if ([string]::IsNullOrWhiteSpace($RepoRoot)) {
    $scriptRoot = Split-Path -Parent $PSCommandPath
    $RepoRoot = Join-Path $scriptRoot ".."
}

$RepoRoot = (Resolve-Path -LiteralPath $RepoRoot).Path
$androidNs = "http://schemas.android.com/apk/res/android"
$appNs = "http://schemas.android.com/apk/res-auto"

Add-Type -AssemblyName System.IO.Compression.FileSystem

function Load-XmlDocument {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Missing XML file: $Path"
    }

    $doc = New-Object System.Xml.XmlDocument
    $doc.PreserveWhitespace = $false
    $doc.Load($Path)
    return $doc
}

function Save-XmlDocument {
    param(
        [System.Xml.XmlDocument]$Document,
        [string]$Path
    )

    $settings = New-Object System.Xml.XmlWriterSettings
    $settings.Encoding = New-Object System.Text.UTF8Encoding($false)
    $settings.Indent = $true
    $settings.NewLineChars = "`r`n"

    $writer = [System.Xml.XmlWriter]::Create($Path, $settings)
    try {
        $Document.Save($writer)
    } finally {
        $writer.Close()
    }
}

function New-NamespaceManager {
    param([System.Xml.XmlDocument]$Document)

    $ns = New-Object System.Xml.XmlNamespaceManager($Document.NameTable)
    $ns.AddNamespace("android", $androidNs)
    $ns.AddNamespace("app", $appNs)
    return $ns
}

function Set-NamespacedAttribute {
    param(
        [System.Xml.XmlDocument]$Document,
        [System.Xml.XmlElement]$Element,
        [string]$Prefix,
        [string]$Namespace,
        [string]$Name,
        [string]$Value
    )

    $attribute = $Document.CreateAttribute($Prefix, $Name, $Namespace)
    $attribute.Value = $Value
    [void]$Element.Attributes.Append($attribute)
}

function Remove-ExistingCheatBadges {
    param([System.Xml.XmlDocument]$Document)

    $nodes = @($Document.GetElementsByTagName("*") | Where-Object {
        $_.GetAttribute("tag", $androidNs) -eq "cheat_badge"
    })
    foreach ($node in $nodes) {
        [void]$node.ParentNode.RemoveChild($node)
    }
}

function New-CheatBadge {
    param(
        [System.Xml.XmlDocument]$Document,
        [string]$TextSize,
        [string]$PaddingX,
        [string]$PaddingY,
        [string]$MarginStart,
        [string]$MarginTop,
        [hashtable]$AppAttributes
    )

    $badge = $Document.CreateElement("TextView")
    $androidAttributes = @(
        @("tag", "cheat_badge"),
        @("layout_width", "wrap_content"),
        @("layout_height", "wrap_content"),
        @("layout_marginStart", $MarginStart),
        @("layout_marginTop", $MarginTop),
        @("background", "#D5227A48"),
        @("elevation", "8.0dip"),
        @("paddingLeft", $PaddingX),
        @("paddingRight", $PaddingX),
        @("paddingTop", $PaddingY),
        @("paddingBottom", $PaddingY),
        @("text", "CHEATS"),
        @("textColor", "#FFFFFFFF"),
        @("textSize", $TextSize),
        @("textStyle", "bold"),
        @("visibility", "gone")
    )

    foreach ($attribute in $androidAttributes) {
        Set-NamespacedAttribute -Document $Document -Element $badge -Prefix "android" -Namespace $androidNs -Name $attribute[0] -Value $attribute[1]
    }

    foreach ($name in $AppAttributes.Keys) {
        Set-NamespacedAttribute -Document $Document -Element $badge -Prefix "app" -Namespace $appNs -Name $name -Value $AppAttributes[$name]
    }

    return $badge
}

function Update-GridLayout {
    $path = Join-Path $ProjectPath "res\layout\layout_game_grid_entry.xml"
    $doc = Load-XmlDocument -Path $path
    Remove-ExistingCheatBadges -Document $doc

    $badge = New-CheatBadge -Document $doc -TextSize "11.0sp" -PaddingX "7.0dip" -PaddingY "3.0dip" -MarginStart "8.0dip" -MarginTop "8.0dip" -AppAttributes @{
        layout_constraintStart_toStartOf = "parent"
        layout_constraintTop_toTopOf = "parent"
    }

    [void]$doc.DocumentElement.AppendChild($badge)
    Save-XmlDocument -Document $doc -Path $path
}

function Update-ListLayout {
    $path = Join-Path $ProjectPath "res\layout\layout_game_list_entry.xml"
    $doc = Load-XmlDocument -Path $path
    Remove-ExistingCheatBadges -Document $doc

    $badge = New-CheatBadge -Document $doc -TextSize "8.0sp" -PaddingX "4.0dip" -PaddingY "1.0dip" -MarginStart "6.0dip" -MarginTop "3.0dip" -AppAttributes @{
        layout_constraintStart_toStartOf = "@id/game_list_view_entry_type_icon"
        layout_constraintTop_toTopOf = "@id/game_list_view_entry_type_icon"
    }

    [void]$doc.DocumentElement.AppendChild($badge)
    Save-XmlDocument -Document $doc -Path $path
}

function Write-CheatSupportClass {
    $targetDir = Join-Path $ProjectPath "smali\xyz\aethersx2\android"
    if (-not (Test-Path -LiteralPath $targetDir)) {
        throw "Missing smali package folder: $targetDir"
    }

    $targetPath = Join-Path $targetDir "CheatSupport.smali"
    $content = @'
.class public final Lxyz/aethersx2/android/CheatSupport;
.super Ljava/lang/Object;
.source "CheatSupport.java"


# direct methods
.method private constructor <init>()V
    .locals 0

    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    return-void
.end method

.method private static hasCheatFileInRoot(Ljava/io/File;Ljava/lang/String;)Z
    .locals 3

    const/4 v0, 0x0

    if-eqz p0, :cond_return

    new-instance v1, Ljava/io/File;

    const-string v2, "cheats"

    invoke-direct {v1, p0, v2}, Ljava/io/File;-><init>(Ljava/io/File;Ljava/lang/String;)V

    new-instance v2, Ljava/io/File;

    invoke-direct {v2, v1, p1}, Ljava/io/File;-><init>(Ljava/io/File;Ljava/lang/String;)V

    invoke-static {v2}, Lxyz/aethersx2/android/CheatSupport;->hasRealCheatFile(Ljava/io/File;)Z

    move-result v0

    if-nez v0, :cond_return

    invoke-virtual {p1}, Ljava/lang/String;->toLowerCase()Ljava/lang/String;

    move-result-object p1

    new-instance v2, Ljava/io/File;

    invoke-direct {v2, v1, p1}, Ljava/io/File;-><init>(Ljava/io/File;Ljava/lang/String;)V

    invoke-static {v2}, Lxyz/aethersx2/android/CheatSupport;->hasRealCheatFile(Ljava/io/File;)Z

    move-result v0

    :cond_return
    return v0
.end method

.method private static hasRealCheatFile(Ljava/io/File;)Z
    .locals 5

    const/4 v0, 0x0

    if-eqz p0, :cond_return

    invoke-virtual {p0}, Ljava/io/File;->isFile()Z

    move-result v1

    if-eqz v1, :cond_return

    :try_start_0
    invoke-virtual {p0}, Ljava/io/File;->toPath()Ljava/nio/file/Path;

    move-result-object v1

    invoke-static {v1}, Ljava/nio/file/Files;->readAllLines(Ljava/nio/file/Path;)Ljava/util/List;

    move-result-object v1

    const/4 v2, 0x0

    :goto_loop
    invoke-interface {v1}, Ljava/util/List;->size()I

    move-result v3

    if-ge v2, v3, :cond_return

    invoke-interface {v1, v2}, Ljava/util/List;->get(I)Ljava/lang/Object;

    move-result-object v3

    check-cast v3, Ljava/lang/String;

    invoke-static {v3}, Lxyz/aethersx2/android/CheatSupport;->isPatchLine(Ljava/lang/String;)Z

    move-result v4

    if-eqz v4, :cond_next

    const/4 v0, 0x1

    return v0

    :cond_next
    add-int/lit8 v2, v2, 0x1

    goto :goto_loop
    :try_end_0
    .catch Ljava/lang/Exception; {:try_start_0 .. :try_end_0} :catch_0

    :catch_0
    :cond_return
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

.method public static hasCheats(Landroid/content/Context;I)Z
    .locals 4

    const/4 v0, 0x0

    if-eqz p0, :cond_return_false

    const-string v1, "%08X.pnach"

    const/4 v2, 0x1

    new-array v2, v2, [Ljava/lang/Object;

    invoke-static {p1}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;

    move-result-object p1

    aput-object p1, v2, v0

    invoke-static {v1, v2}, Ljava/lang/String;->format(Ljava/lang/String;[Ljava/lang/Object;)Ljava/lang/String;

    move-result-object p1

    const/4 v1, 0x0

    invoke-virtual {p0, v1}, Landroid/content/Context;->getExternalFilesDir(Ljava/lang/String;)Ljava/io/File;

    move-result-object p0

    invoke-static {p0, p1}, Lxyz/aethersx2/android/CheatSupport;->hasCheatFileInRoot(Ljava/io/File;Ljava/lang/String;)Z

    move-result p0

    return p0

    :cond_return_false
    return v0
.end method
'@

    [System.IO.File]::WriteAllText($targetPath, (ConvertTo-Lf -Text $content), (New-Object System.Text.UTF8Encoding($false)))
    Write-Host "Generated CheatSupport.smali for runtime .pnach patch-line checks"
}

function ConvertTo-Lf {
    param([string]$Text)
    return ($Text -replace "`r`n", "`n")
}

function Read-Smali {
    param([string]$Path)
    return ConvertTo-Lf -Text ([System.IO.File]::ReadAllText($Path))
}

function Write-Smali {
    param(
        [string]$Path,
        [string]$Text
    )

    [System.IO.File]::WriteAllText($Path, (ConvertTo-Lf -Text $Text), (New-Object System.Text.UTF8Encoding($false)))
}

function Replace-Required {
    param(
        [string]$Text,
        [string]$Old,
        [string]$New,
        [string]$Description
    )

    $oldLf = ConvertTo-Lf -Text $Old
    $newLf = ConvertTo-Lf -Text $New

    if (-not $Text.Contains($oldLf)) {
        throw "Could not patch $Description."
    }

    return $Text.Replace($oldLf, $newLf)
}

function Patch-GridViewHolder {
    $path = Join-Path $ProjectPath "smali\xyz\aethersx2\android\c`$b.smali"
    $text = Read-Smali -Path $path

    if (-not $text.Contains(".field public final E:Landroid/view/View;")) {
        $text = Replace-Required -Text $text -Description "grid view holder badge field" -Old @'
.field public D:Lxyz/aethersx2/android/GameListEntry;
'@ -New @'
.field public D:Lxyz/aethersx2/android/GameListEntry;

.field public final E:Landroid/view/View;
'@
    }

    if (-not $text.Contains("Lxyz/aethersx2/android/c`$b;->E:Landroid/view/View;")) {
        $text = Replace-Required -Text $text -Description "grid view holder badge lookup" -Old @'
    .line 5
    invoke-virtual {p1, p0}, Landroid/view/View;->setOnLongClickListener(Landroid/view/View$OnLongClickListener;)V

    return-void
'@ -New @'
    .line 5
    invoke-virtual {p1, p0}, Landroid/view/View;->setOnLongClickListener(Landroid/view/View$OnLongClickListener;)V

    const-string p1, "cheat_badge"

    invoke-virtual {p2, p1}, Landroid/view/View;->findViewWithTag(Ljava/lang/Object;)Landroid/view/View;

    move-result-object p1

    iput-object p1, p0, Lxyz/aethersx2/android/c$b;->E:Landroid/view/View;

    return-void
'@
    }

    Write-Smali -Path $path -Text $text
}

function Patch-ListViewHolder {
    $path = Join-Path $ProjectPath "smali\xyz\aethersx2\android\e`$b.smali"
    $text = Read-Smali -Path $path

    if (-not $text.Contains(".field public E:Landroid/view/View;")) {
        $text = Replace-Required -Text $text -Description "list view holder badge field" -Old @'
.field public D:Lxyz/aethersx2/android/GameListEntry;
'@ -New @'
.field public D:Lxyz/aethersx2/android/GameListEntry;

.field public E:Landroid/view/View;
'@
    }

    if (-not $text.Contains("Lxyz/aethersx2/android/e`$b;->E:Landroid/view/View;")) {
        $text = Replace-Required -Text $text -Description "list view holder badge lookup" -Old @'
    .line 5
    iget-object p1, p0, Lxyz/aethersx2/android/e$b;->C:Landroid/view/View;

    invoke-virtual {p1, p0}, Landroid/view/View;->setOnLongClickListener(Landroid/view/View$OnLongClickListener;)V

    return-void
'@ -New @'
    .line 5
    iget-object p1, p0, Lxyz/aethersx2/android/e$b;->C:Landroid/view/View;

    invoke-virtual {p1, p0}, Landroid/view/View;->setOnLongClickListener(Landroid/view/View$OnLongClickListener;)V

    const-string p1, "cheat_badge"

    invoke-virtual {p2, p1}, Landroid/view/View;->findViewWithTag(Ljava/lang/Object;)Landroid/view/View;

    move-result-object p1

    iput-object p1, p0, Lxyz/aethersx2/android/e$b;->E:Landroid/view/View;

    return-void
'@
    }

    Write-Smali -Path $path -Text $text
}

function Patch-GridAdapter {
    $path = Join-Path $ProjectPath "smali\xyz\aethersx2\android\c`$a.smali"
    $text = Read-Smali -Path $path

    if ($text.Contains("Lxyz/aethersx2/android/CheatSupport;->hasCheats(I)Z")) {
        $text = Replace-Required -Text $text -Description "grid adapter runtime cheat lookup locals" -Old @'
.method public final h(Landroidx/recyclerview/widget/RecyclerView$b0;I)V
    .locals 3
'@ -New @'
.method public final h(Landroidx/recyclerview/widget/RecyclerView$b0;I)V
    .locals 4
'@

        $text = Replace-Required -Text $text -Description "grid adapter runtime cheat lookup" -Old @'
    invoke-virtual {p2}, Lxyz/aethersx2/android/GameListEntry;->getCRC()I

    move-result v2

    invoke-static {v2}, Lxyz/aethersx2/android/CheatSupport;->hasCheats(I)Z

    move-result v2
'@ -New @'
    invoke-virtual {p2}, Lxyz/aethersx2/android/GameListEntry;->getCRC()I

    move-result v2

    invoke-virtual {v1}, Landroid/view/View;->getContext()Landroid/content/Context;

    move-result-object v3

    invoke-static {v3, v2}, Lxyz/aethersx2/android/CheatSupport;->hasCheats(Landroid/content/Context;I)Z

    move-result v2
'@
    } elseif (-not $text.Contains("Lxyz/aethersx2/android/CheatSupport;->hasCheats(Landroid/content/Context;I)Z")) {
        $text = Replace-Required -Text $text -Description "grid adapter locals" -Old @'
.method public final h(Landroidx/recyclerview/widget/RecyclerView$b0;I)V
    .locals 2
'@ -New @'
.method public final h(Landroidx/recyclerview/widget/RecyclerView$b0;I)V
    .locals 4
'@

        $text = Replace-Required -Text $text -Description "grid adapter badge binding" -Old @'
    .line 4
    :goto_0
    iput-object p2, p1, Lxyz/aethersx2/android/c$b;->D:Lxyz/aethersx2/android/GameListEntry;

    .line 5
    iget-object p1, p1, Lxyz/aethersx2/android/c$b;->C:Landroid/widget/ImageView;
'@ -New @'
    .line 4
    :goto_0
    iput-object p2, p1, Lxyz/aethersx2/android/c$b;->D:Lxyz/aethersx2/android/GameListEntry;

    iget-object v1, p1, Lxyz/aethersx2/android/c$b;->E:Landroid/view/View;

    if-eqz v1, :cond_cheat_badge_done

    invoke-virtual {p2}, Lxyz/aethersx2/android/GameListEntry;->getCRC()I

    move-result v2

    invoke-virtual {v1}, Landroid/view/View;->getContext()Landroid/content/Context;

    move-result-object v3

    invoke-static {v3, v2}, Lxyz/aethersx2/android/CheatSupport;->hasCheats(Landroid/content/Context;I)Z

    move-result v2

    if-eqz v2, :cond_cheat_badge_hidden

    const/4 v2, 0x0

    goto :goto_cheat_badge_visibility

    :cond_cheat_badge_hidden
    const/16 v2, 0x8

    :goto_cheat_badge_visibility
    invoke-virtual {v1, v2}, Landroid/view/View;->setVisibility(I)V

    :cond_cheat_badge_done
    .line 5
    iget-object p1, p1, Lxyz/aethersx2/android/c$b;->C:Landroid/widget/ImageView;
'@
    }

    Write-Smali -Path $path -Text $text
}

function Patch-ListAdapter {
    $path = Join-Path $ProjectPath "smali\xyz\aethersx2\android\e`$a.smali"
    $text = Read-Smali -Path $path

    if ($text.Contains("Lxyz/aethersx2/android/CheatSupport;->hasCheats(I)Z")) {
        $text = Replace-Required -Text $text -Description "list adapter runtime cheat lookup" -Old @'
    invoke-virtual {p2}, Lxyz/aethersx2/android/GameListEntry;->getCRC()I

    move-result v2

    invoke-static {v2}, Lxyz/aethersx2/android/CheatSupport;->hasCheats(I)Z

    move-result v2
'@ -New @'
    invoke-virtual {p2}, Lxyz/aethersx2/android/GameListEntry;->getCRC()I

    move-result v2

    invoke-virtual {v1}, Landroid/view/View;->getContext()Landroid/content/Context;

    move-result-object v3

    invoke-static {v3, v2}, Lxyz/aethersx2/android/CheatSupport;->hasCheats(Landroid/content/Context;I)Z

    move-result v2
'@
    } elseif (-not $text.Contains("Lxyz/aethersx2/android/CheatSupport;->hasCheats(Landroid/content/Context;I)Z")) {
        $text = Replace-Required -Text $text -Description "list adapter badge binding" -Old @'
    .line 4
    :goto_0
    iput-object p2, p1, Lxyz/aethersx2/android/e$b;->D:Lxyz/aethersx2/android/GameListEntry;

    .line 5
    iget-object v1, p1, Lxyz/aethersx2/android/e$b;->C:Landroid/view/View;
'@ -New @'
    .line 4
    :goto_0
    iput-object p2, p1, Lxyz/aethersx2/android/e$b;->D:Lxyz/aethersx2/android/GameListEntry;

    iget-object v1, p1, Lxyz/aethersx2/android/e$b;->E:Landroid/view/View;

    if-eqz v1, :cond_cheat_badge_done

    invoke-virtual {p2}, Lxyz/aethersx2/android/GameListEntry;->getCRC()I

    move-result v2

    invoke-virtual {v1}, Landroid/view/View;->getContext()Landroid/content/Context;

    move-result-object v3

    invoke-static {v3, v2}, Lxyz/aethersx2/android/CheatSupport;->hasCheats(Landroid/content/Context;I)Z

    move-result v2

    if-eqz v2, :cond_cheat_badge_hidden

    const/4 v2, 0x0

    goto :goto_cheat_badge_visibility

    :cond_cheat_badge_hidden
    const/16 v2, 0x8

    :goto_cheat_badge_visibility
    invoke-virtual {v1, v2}, Landroid/view/View;->setVisibility(I)V

    :cond_cheat_badge_done
    .line 5
    iget-object v1, p1, Lxyz/aethersx2/android/e$b;->C:Landroid/view/View;
'@
    }

    Write-Smali -Path $path -Text $text
}

Update-GridLayout
Update-ListLayout
Write-CheatSupportClass
Patch-GridViewHolder
Patch-ListViewHolder
Patch-GridAdapter
Patch-ListAdapter

Write-Host "Game list cheat badges updated in $ProjectPath"
