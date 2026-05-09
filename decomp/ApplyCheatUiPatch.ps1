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
$appNs = "http://schemas.android.com/apk/res-auto"

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

function New-AppAttribute {
    param(
        [System.Xml.XmlDocument]$Document,
        [string]$Name,
        [string]$Value
    )

    $attribute = $Document.CreateAttribute("app", $Name, $appNs)
    $attribute.Value = $Value
    return $attribute
}

function New-Preference {
    param(
        [System.Xml.XmlDocument]$Document,
        [string]$ElementName,
        [hashtable]$Attributes
    )

    $preference = $Document.CreateElement($ElementName)
    foreach ($name in $Attributes.Keys) {
        [void]$preference.Attributes.Append((New-AppAttribute -Document $Document -Name $name -Value $Attributes[$name]))
    }
    return $preference
}

function Remove-PreferenceByKey {
    param(
        [System.Xml.XmlDocument]$Document,
        [string]$Key
    )

    $ns = New-Object System.Xml.XmlNamespaceManager($Document.NameTable)
    $ns.AddNamespace("app", $appNs)

    $nodes = @($Document.SelectNodes("//*[@app:key='$Key']", $ns))
    foreach ($node in $nodes) {
        [void]$node.ParentNode.RemoveChild($node)
    }
}

function Remove-CheatCategory {
    param([System.Xml.XmlDocument]$Document)

    $ns = New-Object System.Xml.XmlNamespaceManager($Document.NameTable)
    $ns.AddNamespace("app", $appNs)

    $nodes = @($Document.SelectNodes("/PreferenceScreen/PreferenceCategory[@app:title='Cheats and Patches']", $ns))
    foreach ($node in $nodes) {
        [void]$node.ParentNode.RemoveChild($node)
    }
}

function Add-CheatCategory {
    param(
        [System.Xml.XmlDocument]$Document,
        [string]$Mode,
        [string]$AfterCategoryTitle
    )

    Remove-CheatCategory -Document $Document

    $screen = $Document.DocumentElement
    $category = $Document.CreateElement("PreferenceCategory")
    [void]$category.Attributes.Append((New-AppAttribute -Document $Document -Name "iconSpaceReserved" -Value "false"))
    [void]$category.Attributes.Append((New-AppAttribute -Document $Document -Name "title" -Value "Cheats and Patches"))

    if ($Mode -eq "Global") {
        $type = "SwitchPreferenceCompat"
        $common = @{
            iconSpaceReserved = "false"
            useSimpleSummaryProvider = "true"
        }

        [void]$category.AppendChild((New-Preference -Document $Document -ElementName $type -Attributes ($common + @{
            defaultValue = "true"
            key = "EmuCore/EnableCheats"
            summary = "@string/settings_summary_patch_codes"
            title = "@string/settings_patch_codes"
        })))
        [void]$category.AppendChild((New-Preference -Document $Document -ElementName $type -Attributes ($common + @{
            defaultValue = "false"
            key = "EmuCore/EnableWideScreenPatches"
            summary = "@string/settings_summary_widescreen_patches"
            title = "@string/settings_widescreen_patches"
        })))
        [void]$category.AppendChild((New-Preference -Document $Document -ElementName $type -Attributes ($common + @{
            defaultValue = "false"
            key = "EmuCore/EnableNoInterlacingPatches"
            summary = "@string/settings_summary_no_interlacing_patches"
            title = "@string/settings_no_interlacing_patches"
        })))
    } elseif ($Mode -eq "Game") {
        $type = "xyz.aethersx2.android.TriStatePreference"
        $common = @{
            iconSpaceReserved = "false"
            useSimpleSummaryProvider = "true"
        }

        [void]$category.AppendChild((New-Preference -Document $Document -ElementName $type -Attributes ($common + @{
            key = "EmuCore/EnableCheats"
            summary = "@string/settings_summary_patch_codes"
            title = "@string/settings_patch_codes"
        })))
        [void]$category.AppendChild((New-Preference -Document $Document -ElementName $type -Attributes ($common + @{
            key = "EmuCore/EnableWideScreenPatches"
            summary = "@string/settings_summary_widescreen_patches"
            title = "@string/settings_widescreen_patches"
        })))
        [void]$category.AppendChild((New-Preference -Document $Document -ElementName $type -Attributes ($common + @{
            key = "EmuCore/EnableNoInterlacingPatches"
            summary = "@string/settings_summary_no_interlacing_patches"
            title = "@string/settings_no_interlacing_patches"
        })))
    } else {
        throw "Unknown cheat category mode: $Mode"
    }

    $ns = New-Object System.Xml.XmlNamespaceManager($Document.NameTable)
    $ns.AddNamespace("app", $appNs)
    $anchor = $Document.SelectSingleNode("/PreferenceScreen/PreferenceCategory[@app:title='$AfterCategoryTitle']", $ns)

    if ($null -ne $anchor -and $null -ne $anchor.NextSibling) {
        [void]$screen.InsertAfter($category, $anchor)
    } else {
        [void]$screen.AppendChild($category)
    }
}

function Update-StringValue {
    param(
        [System.Xml.XmlDocument]$Document,
        [string]$Name,
        [string]$Value
    )

    $node = $Document.SelectSingleNode("/resources/string[@name='$Name']")
    if ($null -eq $node) {
        throw "Missing string resource: $Name"
    }

    $node.InnerText = $Value
}

$stringsPath = Join-Path $ProjectPath "res\values\strings.xml"
$stringsDoc = Load-XmlDocument -Path $stringsPath
Update-StringValue -Document $stringsDoc -Name "settings_patch_codes" -Value "Enable Cheats"
Update-StringValue -Document $stringsDoc -Name "settings_summary_patch_codes" -Value "Uses user cheat files from the cheats folder for the current game."
Update-StringValue -Document $stringsDoc -Name "settings_widescreen_patches" -Value "Enable Widescreen Patches"
Update-StringValue -Document $stringsDoc -Name "settings_summary_widescreen_patches" -Value "Uses bundled widescreen patches for supported games."
Update-StringValue -Document $stringsDoc -Name "settings_no_interlacing_patches" -Value "Enable No-Interlacing Patches"
Update-StringValue -Document $stringsDoc -Name "settings_summary_no_interlacing_patches" -Value "Uses bundled no-interlacing patches for supported games."
Save-XmlDocument -Document $stringsDoc -Path $stringsPath

$generalPath = Join-Path $ProjectPath "res\xml\general_preferences.xml"
$generalDoc = Load-XmlDocument -Path $generalPath
Remove-PreferenceByKey -Document $generalDoc -Key "EmuCore/EnableCheats"
Add-CheatCategory -Document $generalDoc -Mode "Global" -AfterCategoryTitle "@string/settings_category_interface"
Save-XmlDocument -Document $generalDoc -Path $generalPath

$graphicsPath = Join-Path $ProjectPath "res\xml\graphics_preferences.xml"
$graphicsDoc = Load-XmlDocument -Path $graphicsPath
Remove-PreferenceByKey -Document $graphicsDoc -Key "EmuCore/EnableWideScreenPatches"
Remove-PreferenceByKey -Document $graphicsDoc -Key "EmuCore/EnableNoInterlacingPatches"
Save-XmlDocument -Document $graphicsDoc -Path $graphicsPath

$gameGeneralPath = Join-Path $ProjectPath "res\xml\general_game_settings_preferences.xml"
$gameGeneralDoc = Load-XmlDocument -Path $gameGeneralPath
Remove-PreferenceByKey -Document $gameGeneralDoc -Key "EmuCore/EnableCheats"
Add-CheatCategory -Document $gameGeneralDoc -Mode "Game" -AfterCategoryTitle "@string/settings_category_presets"
Save-XmlDocument -Document $gameGeneralDoc -Path $gameGeneralPath

$gameGraphicsPath = Join-Path $ProjectPath "res\xml\graphics_game_settings_preferences.xml"
$gameGraphicsDoc = Load-XmlDocument -Path $gameGraphicsPath
Remove-PreferenceByKey -Document $gameGraphicsDoc -Key "EmuCore/EnableWideScreenPatches"
Remove-PreferenceByKey -Document $gameGraphicsDoc -Key "EmuCore/EnableNoInterlacingPatches"
Save-XmlDocument -Document $gameGraphicsDoc -Path $gameGraphicsPath

Write-Host "Cheats and Patches settings UI updated in $ProjectPath"
