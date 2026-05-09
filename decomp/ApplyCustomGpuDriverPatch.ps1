param(
    [string]$ProjectPath = "",
    [string]$RepoRoot = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$androidNs = "http://schemas.android.com/apk/res/android"
$appNs = "http://schemas.android.com/apk/res-auto"

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

function Add-GpuDriverPreference {
    param([System.Xml.XmlDocument]$Document)

    Remove-PreferenceByKey -Document $Document -Key "__GPU_DRIVER_MANAGER__"

    $ns = New-Object System.Xml.XmlNamespaceManager($Document.NameTable)
    $ns.AddNamespace("app", $appNs)
    $firstCategory = $Document.SelectSingleNode("/PreferenceScreen/PreferenceCategory[1]", $ns)
    if ($null -eq $firstCategory) {
        throw "Could not find first graphics preference category."
    }

    $preference = $Document.CreateElement("Preference")
    [void]$preference.Attributes.Append((New-AppAttribute -Document $Document -Name "iconSpaceReserved" -Value "false"))
    [void]$preference.Attributes.Append((New-AppAttribute -Document $Document -Name "key" -Value "__GPU_DRIVER_MANAGER__"))
    [void]$preference.Attributes.Append((New-AppAttribute -Document $Document -Name "title" -Value "@string/settings_custom_gpu_driver"))
    [void]$preference.Attributes.Append((New-AppAttribute -Document $Document -Name "summary" -Value "@string/settings_summary_custom_gpu_driver"))

    $intent = $Document.CreateElement("intent")
    $targetPackage = $Document.CreateAttribute("android", "targetPackage", $androidNs)
    $targetPackage.Value = "xyz.aethersx2.android"
    [void]$intent.Attributes.Append($targetPackage)
    $targetClass = $Document.CreateAttribute("android", "targetClass", $androidNs)
    $targetClass.Value = "xyz.aethersx2.android.GpuDriverManagerActivity"
    [void]$intent.Attributes.Append($targetClass)
    [void]$preference.AppendChild($intent)

    $renderer = $Document.SelectSingleNode("/PreferenceScreen/PreferenceCategory[1]/*[@app:key='EmuCore/GS/Renderer']", $ns)
    if ($null -ne $renderer) {
        [void]$firstCategory.InsertAfter($preference, $renderer)
    } else {
        [void]$firstCategory.PrependChild($preference)
    }
}

function Update-Manifest {
    $manifestPath = Join-Path $ProjectPath "AndroidManifest.xml"
    $doc = Load-XmlDocument -Path $manifestPath
    $ns = New-Object System.Xml.XmlNamespaceManager($doc.NameTable)
    $ns.AddNamespace("android", $androidNs)

    $application = $doc.SelectSingleNode("/manifest/application")
    if ($null -eq $application) {
        throw "Manifest is missing application element."
    }

    $existing = $doc.SelectSingleNode("/manifest/application/activity[@android:name='xyz.aethersx2.android.GpuDriverManagerActivity']", $ns)
    if ($null -eq $existing) {
        $activity = $doc.CreateElement("activity")
        Set-AndroidAttribute -Document $doc -Element $activity -Name "exported" -Value "false"
        Set-AndroidAttribute -Document $doc -Element $activity -Name "label" -Value "@string/settings_custom_gpu_driver"
        Set-AndroidAttribute -Document $doc -Element $activity -Name "name" -Value "xyz.aethersx2.android.GpuDriverManagerActivity"
        Set-AndroidAttribute -Document $doc -Element $activity -Name "theme" -Value "@style/AppTheme"
        [void]$application.PrependChild($activity)
    }

    Save-XmlDocument -Document $doc -Path $manifestPath
}

function Update-Strings {
    $stringsPath = Join-Path $ProjectPath "res\values\strings.xml"
    $doc = Load-XmlDocument -Path $stringsPath
    Set-StringValue -Document $doc -Name "settings_custom_gpu_driver" -Value "Custom GPU Driver"
    Set-StringValue -Document $doc -Name "settings_summary_custom_gpu_driver" -Value "Download, install, and switch Turnip Vulkan drivers for Adreno devices. Applies after restarting the emulator."
    Save-XmlDocument -Document $doc -Path $stringsPath
}

function Update-GraphicsPreferences {
    $graphicsPath = Join-Path $ProjectPath "res\xml\graphics_preferences.xml"
    $doc = Load-XmlDocument -Path $graphicsPath
    Add-GpuDriverPreference -Document $doc
    Save-XmlDocument -Document $doc -Path $graphicsPath
}

function Build-And-Copy-ActivityDex {
    $srcPath = Join-Path $RepoRoot "android-src\xyz\aethersx2\android\GpuDriverManagerActivity.java"
    if (-not (Test-Path -LiteralPath $srcPath)) {
        throw "Missing GPU driver manager Java source: $srcPath"
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

    $buildRoot = Join-Path $RepoRoot ".tools\gpu-driver-activity"
    $classesDir = Join-Path $buildRoot "classes"
    $dexDir = Join-Path $buildRoot "dex"
    if (Test-Path -LiteralPath $buildRoot) {
        Remove-Item -LiteralPath $buildRoot -Recurse -Force
    }
    [void](New-Item -ItemType Directory -Path $classesDir -Force)
    [void](New-Item -ItemType Directory -Path $dexDir -Force)

    & $javac -source 8 -target 8 -Xlint:-options -classpath $androidJar -d $classesDir $srcPath
    if ($LASTEXITCODE -ne 0) {
        throw "javac failed for GPU driver manager activity."
    }

    & $d8 --min-api 23 --lib $androidJar --output $dexDir (Join-Path $classesDir "xyz\aethersx2\android\GpuDriverManagerActivity.class")
    if ($LASTEXITCODE -ne 0) {
        throw "d8 failed for GPU driver manager activity."
    }

    $dexPath = Join-Path $dexDir "classes.dex"
    if (-not (Test-Path -LiteralPath $dexPath)) {
        throw "d8 did not produce classes.dex."
    }
    Copy-Item -LiteralPath $dexPath -Destination (Join-Path $ProjectPath "classes2.dex") -Force
}

function Build-And-Copy-NativeShim {
    $outDir = Join-Path $RepoRoot ".tools\gpu-driver-shim\arm64-v8a"
    $expected = @("libvulkad.so", "libhook_impl.so", "libmain_hook.so")
    $missing = $false
    foreach ($name in $expected) {
        if (-not (Test-Path -LiteralPath (Join-Path $outDir $name))) {
            $missing = $true
        }
    }

    if ($missing) {
        & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $RepoRoot "tools\BuildGpuDriverShim.ps1") -RepoRoot $RepoRoot -OutDir $outDir
        if ($LASTEXITCODE -ne 0) {
            throw "Building the GPU driver shim failed."
        }
    }

    $targetDir = Join-Path $ProjectPath "lib\arm64-v8a"
    [void](New-Item -ItemType Directory -Path $targetDir -Force)
    foreach ($name in $expected) {
        Copy-Item -LiteralPath (Join-Path $outDir $name) -Destination (Join-Path $targetDir $name) -Force
    }
}

function Copy-ThirdPartyNotices {
    $notice = Join-Path $RepoRoot "third_party_notices\libadrenotools-BSD-2-Clause.txt"
    if (-not (Test-Path -LiteralPath $notice)) {
        throw "Missing third-party notice: $notice"
    }

    $targetDir = Join-Path $ProjectPath "assets\licenses"
    [void](New-Item -ItemType Directory -Path $targetDir -Force)
    Copy-Item -LiteralPath $notice -Destination (Join-Path $targetDir "libadrenotools-BSD-2-Clause.txt") -Force
}

function Patch-EmuCoreVulkanLibraryName {
    $libPath = Join-Path $ProjectPath "lib\arm64-v8a\libemucore.so"
    if (-not (Test-Path -LiteralPath $libPath)) {
        throw "Missing native library: $libPath"
    }

    [byte[]]$bytes = [System.IO.File]::ReadAllBytes($libPath)
    [byte[]]$from = [System.Text.Encoding]::ASCII.GetBytes("libvulkan.so")
    [byte[]]$to = [System.Text.Encoding]::ASCII.GetBytes("libvulkad.so")
    $replacements = 0

    for ($i = 0; $i -le $bytes.Length - $from.Length; $i++) {
        $match = $true
        for ($j = 0; $j -lt $from.Length; $j++) {
            if ($bytes[$i + $j] -ne $from[$j]) {
                $match = $false
                break
            }
        }
        if ($match) {
            for ($j = 0; $j -lt $to.Length; $j++) {
                $bytes[$i + $j] = $to[$j]
            }
            $replacements++
            $i += $from.Length - 1
        }
    }

    if ($replacements -eq 0) {
        [byte[]]$patched = [System.Text.Encoding]::ASCII.GetBytes("libvulkad.so")
        $alreadyPatched = $false
        for ($i = 0; $i -le $bytes.Length - $patched.Length; $i++) {
            $match = $true
            for ($j = 0; $j -lt $patched.Length; $j++) {
                if ($bytes[$i + $j] -ne $patched[$j]) {
                    $match = $false
                    break
                }
            }
            if ($match) {
                $alreadyPatched = $true
                break
            }
        }
        if (-not $alreadyPatched) {
            throw "Could not find libvulkan.so string in libemucore.so."
        }
    } else {
        [System.IO.File]::WriteAllBytes($libPath, $bytes)
    }
}

Update-Manifest
Update-Strings
Update-GraphicsPreferences
Build-And-Copy-ActivityDex
Build-And-Copy-NativeShim
Copy-ThirdPartyNotices
Patch-EmuCoreVulkanLibraryName

Write-Host "Applied custom GPU driver manager and Vulkan shim patch to $ProjectPath"
