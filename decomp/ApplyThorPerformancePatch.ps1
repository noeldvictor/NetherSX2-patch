param(
    [string]$ProjectPath = "NetherSX2",
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
)

$ErrorActionPreference = "Stop"

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
    $settings.Indent = $true
    $settings.Encoding = New-Object System.Text.UTF8Encoding($false)
    $writer = [System.Xml.XmlWriter]::Create($Path, $settings)
    try {
        $Document.Save($writer)
    } finally {
        $writer.Close()
    }
}

function New-AndroidAttribute {
    param(
        [System.Xml.XmlDocument]$Document,
        [string]$Name,
        [string]$Value
    )

    $attr = $Document.CreateAttribute("android", $Name, "http://schemas.android.com/apk/res/android")
    $attr.Value = $Value
    return $attr
}

function New-AppAttribute {
    param(
        [System.Xml.XmlDocument]$Document,
        [string]$Name,
        [string]$Value
    )

    $attr = $Document.CreateAttribute("app", $Name, "http://schemas.android.com/apk/res-auto")
    $attr.Value = $Value
    return $attr
}

function Update-Manifest {
    $manifestPath = Join-Path $ProjectPath "AndroidManifest.xml"
    $doc = Load-XmlDocument -Path $manifestPath
    $ns = New-Object System.Xml.XmlNamespaceManager($doc.NameTable)
    $ns.AddNamespace("android", "http://schemas.android.com/apk/res/android")

    $className = "xyz.aethersx2.android.ThorPerformanceActivity"
    $activity = $doc.SelectSingleNode("/manifest/application/activity[@android:name='$className']", $ns)
    if ($null -eq $activity) {
        $application = $doc.SelectSingleNode("/manifest/application")
        if ($null -eq $application) {
            throw "Could not find manifest application element."
        }

        $activity = $doc.CreateElement("activity")
        [void]$activity.Attributes.Append((New-AndroidAttribute -Document $doc -Name "name" -Value $className))
        [void]$activity.Attributes.Append((New-AndroidAttribute -Document $doc -Name "label" -Value "@string/settings_thor_performance_presets"))
        [void]$activity.Attributes.Append((New-AndroidAttribute -Document $doc -Name "exported" -Value "false"))
        [void]$application.AppendChild($activity)
    }

    Save-XmlDocument -Document $doc -Path $manifestPath
}

function Set-StringValue {
    param(
        [System.Xml.XmlDocument]$Document,
        [string]$Name,
        [string]$Value
    )

    $node = $Document.SelectSingleNode("/resources/string[@name='$Name']")
    if ($null -eq $node) {
        $node = $Document.CreateElement("string")
        $attr = $Document.CreateAttribute("name")
        $attr.Value = $Name
        [void]$node.Attributes.Append($attr)
        [void]$Document.DocumentElement.AppendChild($node)
    }
    $node.InnerText = $Value
}

function Update-Strings {
    $stringsPath = Join-Path $ProjectPath "res\values\strings.xml"
    $doc = Load-XmlDocument -Path $stringsPath
    Set-StringValue -Document $doc -Name "settings_thor_performance_presets" -Value "Thor Performance Presets"
    Set-StringValue -Document $doc -Name "settings_summary_thor_performance_presets" -Value "Apply gameplay-focused defaults for AYN Thor."
    Save-XmlDocument -Document $doc -Path $stringsPath
}

function Update-SystemPreferences {
    $systemPath = Join-Path $ProjectPath "res\xml\system_preferences.xml"
    $doc = Load-XmlDocument -Path $systemPath
    $ns = New-Object System.Xml.XmlNamespaceManager($doc.NameTable)
    $ns.AddNamespace("app", "http://schemas.android.com/apk/res-auto")

    $existing = $doc.SelectSingleNode("//*[@app:key='__THOR_PERFORMANCE_PRESETS__']", $ns)
    if ($null -ne $existing) {
        Save-XmlDocument -Document $doc -Path $systemPath
        return
    }

    $category = $doc.SelectSingleNode("/PreferenceScreen/PreferenceCategory[1]")
    if ($null -eq $category) {
        throw "Could not find system performance category."
    }

    $preference = $doc.CreateElement("Preference")
    [void]$preference.Attributes.Append((New-AppAttribute -Document $doc -Name "iconSpaceReserved" -Value "false"))
    [void]$preference.Attributes.Append((New-AppAttribute -Document $doc -Name "key" -Value "__THOR_PERFORMANCE_PRESETS__"))
    [void]$preference.Attributes.Append((New-AppAttribute -Document $doc -Name "title" -Value "@string/settings_thor_performance_presets"))
    [void]$preference.Attributes.Append((New-AppAttribute -Document $doc -Name "summary" -Value "@string/settings_summary_thor_performance_presets"))

    $intent = $doc.CreateElement("intent")
    [void]$intent.Attributes.Append((New-AndroidAttribute -Document $doc -Name "targetPackage" -Value "xyz.aethersx2.android"))
    [void]$intent.Attributes.Append((New-AndroidAttribute -Document $doc -Name "targetClass" -Value "xyz.aethersx2.android.ThorPerformanceActivity"))
    [void]$preference.AppendChild($intent)

    $after = $doc.SelectSingleNode("/PreferenceScreen/PreferenceCategory[1]/*[@app:key='EmuCore/AffinityControlMode']", $ns)
    if ($null -ne $after) {
        [void]$category.InsertAfter($preference, $after)
    } else {
        [void]$category.AppendChild($preference)
    }

    Save-XmlDocument -Document $doc -Path $systemPath
}

function Build-And-Copy-ActivityDex {
    $srcPath = Join-Path $RepoRoot "android-src\xyz\aethersx2\android\ThorPerformanceActivity.java"
    if (-not (Test-Path -LiteralPath $srcPath)) {
        throw "Missing Thor performance activity Java source: $srcPath"
    }

    $androidSdk = $env:ANDROID_SDK_ROOT
    if ([string]::IsNullOrWhiteSpace($androidSdk)) {
        $androidSdk = $env:ANDROID_HOME
    }
    if ([string]::IsNullOrWhiteSpace($androidSdk)) {
        $androidSdk = Join-Path $env:LOCALAPPDATA "Android\Sdk"
    }
    $platform = Get-ChildItem -LiteralPath (Join-Path $androidSdk "platforms") -Directory -ErrorAction Stop |
        Sort-Object Name -Descending |
        Select-Object -First 1
    $buildTools = Get-ChildItem -LiteralPath (Join-Path $androidSdk "build-tools") -Directory -ErrorAction Stop |
        Sort-Object Name -Descending |
        Select-Object -First 1
    $androidJar = Join-Path $platform.FullName "android.jar"
    $d8 = Join-Path $buildTools.FullName "d8.bat"
    if (-not (Test-Path -LiteralPath $d8)) {
        $d8 = Join-Path $buildTools.FullName "d8"
    }
    if (-not (Test-Path -LiteralPath $d8)) {
        throw "Missing d8 in $($buildTools.FullName)"
    }

    $javac = "C:\Program Files\Microsoft\jdk-17.0.19.10-hotspot\bin\javac.exe"
    if (-not (Test-Path -LiteralPath $javac)) {
        $javacCommand = Get-Command javac -ErrorAction SilentlyContinue
        if ($null -eq $javacCommand) {
            throw "javac not found. Install a JDK or add javac to PATH."
        }
        $javac = $javacCommand.Source
    }

    $jdkHome = Split-Path -Parent (Split-Path -Parent $javac)
    $env:JAVA_HOME = $jdkHome
    $env:PATH = (Join-Path $jdkHome "bin") + ";$env:PATH"

    $buildRoot = Join-Path $RepoRoot ".tools\thor-performance-activity"
    $classesDir = Join-Path $buildRoot "classes"
    $dexDir = Join-Path $buildRoot "dex"
    if (Test-Path -LiteralPath $buildRoot) {
        Remove-Item -LiteralPath $buildRoot -Recurse -Force
    }
    [void](New-Item -ItemType Directory -Path $classesDir -Force)
    [void](New-Item -ItemType Directory -Path $dexDir -Force)

    & $javac -source 8 -target 8 -Xlint:-options -classpath $androidJar -d $classesDir $srcPath
    if ($LASTEXITCODE -ne 0) {
        throw "javac failed for Thor performance activity."
    }

    $classFiles = @(Get-ChildItem -LiteralPath $classesDir -Recurse -Filter "*.class" -File | ForEach-Object { $_.FullName })
    & $d8 --min-api 23 --lib $androidJar --output $dexDir @classFiles
    if ($LASTEXITCODE -ne 0) {
        throw "d8 failed for Thor performance activity."
    }

    $dexPath = Join-Path $dexDir "classes.dex"
    if (-not (Test-Path -LiteralPath $dexPath)) {
        throw "d8 did not produce classes.dex."
    }
    Copy-Item -LiteralPath $dexPath -Destination (Join-Path $ProjectPath "classes3.dex") -Force
}

Update-Manifest
Update-Strings
Update-SystemPreferences
Build-And-Copy-ActivityDex

Write-Host "Applied Thor performance presets patch to $ProjectPath"
