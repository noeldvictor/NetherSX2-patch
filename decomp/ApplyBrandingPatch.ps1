param(
    [string]$ProjectPath = "",
    [string]$RepoRoot = "",
    [string]$AppLabel = "NetherSX2 Thor Experiment"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$androidNs = "http://schemas.android.com/apk/res/android"

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
$brandRes = Join-Path $RepoRoot "branding\android\res"

if (-not (Test-Path -LiteralPath $brandRes)) {
    throw "Missing generated branding resources: $brandRes. Run tools\generate_brand_assets.py first."
}

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

function Set-AndroidAttribute {
    param(
        [System.Xml.XmlDocument]$Document,
        [System.Xml.XmlElement]$Element,
        [string]$Name,
        [string]$Value
    )

    $attribute = $Element.GetAttributeNode($Name, $androidNs)
    if ($null -eq $attribute) {
        $attribute = $Document.CreateAttribute("android", $Name, $androidNs)
        [void]$Element.Attributes.Append($attribute)
    }
    $attribute.Value = $Value
}

function Set-StringValue {
    param(
        [System.Xml.XmlDocument]$Document,
        [string]$Name,
        [string]$Value
    )

    $node = $Document.SelectSingleNode("/resources/string[@name='$Name']")
    if ($null -ne $node) {
        $node.InnerText = $Value
    }
}

function Copy-BrandingResources {
    $projectRes = Join-Path $ProjectPath "res"
    $files = Get-ChildItem -LiteralPath $brandRes -Recurse -File | Where-Object {
        $relative = $_.FullName.Substring($brandRes.Length).TrimStart("\", "/")
        -not $relative.StartsWith("values\", [System.StringComparison]::OrdinalIgnoreCase)
    }

    foreach ($file in $files) {
        $relative = $file.FullName.Substring($brandRes.Length).TrimStart("\", "/")
        $destination = Join-Path $projectRes $relative
        $destinationDir = Split-Path -Parent $destination
        if (-not (Test-Path -LiteralPath $destinationDir)) {
            [void](New-Item -ItemType Directory -Path $destinationDir -Force)
        }
        Copy-Item -LiteralPath $file.FullName -Destination $destination -Force
    }
}

function Update-ManifestBranding {
    $manifestPath = Join-Path $ProjectPath "AndroidManifest.xml"
    $doc = Load-XmlDocument -Path $manifestPath
    $ns = New-Object System.Xml.XmlNamespaceManager($doc.NameTable)
    $ns.AddNamespace("android", $androidNs)

    $application = $doc.SelectSingleNode("/manifest/application")
    if ($null -ne $application) {
        Set-AndroidAttribute -Document $doc -Element $application -Name "label" -Value $AppLabel
        Set-AndroidAttribute -Document $doc -Element $application -Name "icon" -Value "@mipmap/ic_launcher"
        Set-AndroidAttribute -Document $doc -Element $application -Name "roundIcon" -Value "@mipmap/ic_launcher_round"
    }

    $activityNames = @(
        "xyz.aethersx2.android.MainActivity",
        "xyz.aethersx2.android.EmulationActivity"
    )

    foreach ($activityName in $activityNames) {
        $activity = $doc.SelectSingleNode("/manifest/application/activity[@android:name='$activityName']", $ns)
        if ($null -ne $activity) {
            Set-AndroidAttribute -Document $doc -Element $activity -Name "label" -Value $AppLabel
        }
    }

    Save-XmlDocument -Document $doc -Path $manifestPath
}

function Update-DefaultStrings {
    $stringsPath = Join-Path $ProjectPath "res\values\strings.xml"
    $doc = Load-XmlDocument -Path $stringsPath

    Set-StringValue -Document $doc -Name "achievement_settings_login_help" -Value "Please enter user name and password for retroachievements.org below. Your password will not be saved in $AppLabel, an access token will be generated and used instead."
    Set-StringValue -Document $doc -Name "settings_achievements_disclaimer" -Value "$AppLabel uses RetroAchievements (retroachievements.org) as an achievement database and for tracking progress."
    Set-StringValue -Document $doc -Name "settings_summary_achievements_enable" -Value "When enabled and logged in, $AppLabel will scan for achievements on startup."
    Set-StringValue -Document $doc -Name "settings_summary_achievements_test_mode" -Value "When enabled, $AppLabel will assume all achievements are locked and not send any unlock notifications to the server."
    Set-StringValue -Document $doc -Name "setup_wizard_game_directories_message" -Value "$AppLabel will automatically detect games in the locations you specify here. You should add at least one directory to scan. Please do not add the top of your storage volume, otherwise scanning will take a very long time."
    Set-StringValue -Document $doc -Name "setup_wizard_welcome_title" -Value "Welcome to $AppLabel!"

    Save-XmlDocument -Document $doc -Path $stringsPath
}

function Update-LauncherBackgroundColor {
    $colorsPath = Join-Path $ProjectPath "res\values\colors.xml"
    if (-not (Test-Path -LiteralPath $colorsPath)) {
        return
    }

    $doc = Load-XmlDocument -Path $colorsPath
    $node = $doc.SelectSingleNode("/resources/color[@name='ic_launcher_background']")
    if ($null -ne $node) {
        $node.InnerText = "#ff0B141C"
        Save-XmlDocument -Document $doc -Path $colorsPath
    }
}

Copy-BrandingResources
Update-ManifestBranding
Update-DefaultStrings
Update-LauncherBackgroundColor

Write-Host "Applied $AppLabel branding to $ProjectPath"
