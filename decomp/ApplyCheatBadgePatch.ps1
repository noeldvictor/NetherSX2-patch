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

function Get-BundledCheatCrcs {
    $crcSet = New-Object "System.Collections.Generic.HashSet[string]" ([System.StringComparer]::OrdinalIgnoreCase)
    $zipPaths = @(
        Join-Path $RepoRoot "assets\cheats_ws.zip"
        Join-Path $RepoRoot "assets\cheats_ni.zip"
    )

    foreach ($zipPath in $zipPaths) {
        if (-not (Test-Path -LiteralPath $zipPath)) {
            Write-Warning "Missing cheat zip: $zipPath"
            continue
        }

        $archive = [System.IO.Compression.ZipFile]::OpenRead($zipPath)
        try {
            foreach ($entry in $archive.Entries) {
                $name = [System.IO.Path]::GetFileNameWithoutExtension($entry.FullName)
                if ($name -match '^[0-9A-Fa-f]{8}$') {
                    [void]$crcSet.Add($name.ToUpperInvariant())
                }
            }
        } finally {
            $archive.Dispose()
        }
    }

    return @($crcSet)
}

function Convert-CrcToSignedInt64 {
    param([string]$Hex)

    $unsigned = [UInt32]::Parse($Hex, [System.Globalization.NumberStyles]::HexNumber)
    if ($unsigned -gt [UInt32]0x7fffffff) {
        return ([Int64]$unsigned - 0x100000000)
    }

    return [Int64]$unsigned
}

function Write-CheatSupportClass {
    param([string[]]$Crcs)

    if ($Crcs.Count -eq 0) {
        throw "No cheat CRCs found in bundled cheat zips."
    }

    $entries = foreach ($crc in $Crcs) {
        [pscustomobject]@{
            Crc = $crc
            Signed = Convert-CrcToSignedInt64 -Hex $crc
        }
    }

    $entries = @($entries | Sort-Object -Property Signed)
    $targetDir = Join-Path $ProjectPath "smali\xyz\aethersx2\android"
    if (-not (Test-Path -LiteralPath $targetDir)) {
        throw "Missing smali package folder: $targetDir"
    }

    $targetPath = Join-Path $targetDir "CheatSupport.smali"
    $lines = New-Object System.Collections.Generic.List[string]
    [void]$lines.Add(".class public final Lxyz/aethersx2/android/CheatSupport;")
    [void]$lines.Add(".super Ljava/lang/Object;")
    [void]$lines.Add('.source "CheatSupport.java"')
    [void]$lines.Add("")
    [void]$lines.Add("# direct methods")
    [void]$lines.Add(".method private constructor <init>()V")
    [void]$lines.Add("    .locals 0")
    [void]$lines.Add("")
    [void]$lines.Add("    invoke-direct {p0}, Ljava/lang/Object;-><init>()V")
    [void]$lines.Add("")
    [void]$lines.Add("    return-void")
    [void]$lines.Add(".end method")
    [void]$lines.Add("")
    [void]$lines.Add("")
    [void]$lines.Add("# virtual methods")
    [void]$lines.Add(".method public static hasCheats(I)Z")
    [void]$lines.Add("    .locals 1")
    [void]$lines.Add("")
    [void]$lines.Add("    sparse-switch p0, :sswitch_data_0")
    [void]$lines.Add("")
    [void]$lines.Add("    const/4 v0, 0x0")
    [void]$lines.Add("")
    [void]$lines.Add("    return v0")
    [void]$lines.Add("")
    [void]$lines.Add("    :sswitch_has_cheats")
    [void]$lines.Add("    const/4 v0, 0x1")
    [void]$lines.Add("")
    [void]$lines.Add("    return v0")
    [void]$lines.Add("")
    [void]$lines.Add("    :sswitch_data_0")
    [void]$lines.Add("    .sparse-switch")

    foreach ($entry in $entries) {
        [void]$lines.Add(("        {0} -> :sswitch_has_cheats" -f $entry.Signed))
    }

    [void]$lines.Add("    .end sparse-switch")
    [void]$lines.Add(".end method")

    [System.IO.File]::WriteAllLines($targetPath, $lines, (New-Object System.Text.UTF8Encoding($false)))
    Write-Host ("Generated CheatSupport.smali with {0} bundled cheat CRCs" -f $entries.Count)
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

    if (-not $text.Contains("Lxyz/aethersx2/android/CheatSupport;->hasCheats(I)Z")) {
        $text = Replace-Required -Text $text -Description "grid adapter locals" -Old @'
.method public final h(Landroidx/recyclerview/widget/RecyclerView$b0;I)V
    .locals 2
'@ -New @'
.method public final h(Landroidx/recyclerview/widget/RecyclerView$b0;I)V
    .locals 3
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

    invoke-static {v2}, Lxyz/aethersx2/android/CheatSupport;->hasCheats(I)Z

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

    if (-not $text.Contains("Lxyz/aethersx2/android/CheatSupport;->hasCheats(I)Z")) {
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

    invoke-static {v2}, Lxyz/aethersx2/android/CheatSupport;->hasCheats(I)Z

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
Write-CheatSupportClass -Crcs (Get-BundledCheatCrcs)
Patch-GridViewHolder
Patch-ListViewHolder
Patch-GridAdapter
Patch-ListAdapter

Write-Host "Game list cheat badges updated in $ProjectPath"
