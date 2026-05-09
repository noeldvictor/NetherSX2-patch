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
$targetDir = Join-Path $ProjectPath "smali\xyz\aethersx2\android"
if (-not (Test-Path -LiteralPath $targetDir)) {
    throw "Missing smali target directory: $targetDir"
}

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$helperPath = Join-Path $targetDir "ThorHaptics.smali"
$helperSmali = @'
.class public final Lxyz/aethersx2/android/ThorHaptics;
.super Ljava/lang/Object;
.source "ThorHaptics.java"


# direct methods
.method public constructor <init>()V
    .locals 0

    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    return-void
.end method

.method public static apply(Landroid/content/Context;)V
    .locals 4

    :try_start_0
    if-eqz p0, :return

    invoke-static {p0}, Lxyz/aethersx2/android/ThorHaptics;->hasDeviceVibrator(Landroid/content/Context;)Z

    move-result v0

    if-eqz v0, :return

    invoke-static {p0}, Landroidx/preference/PreferenceManager;->getDefaultSharedPreferences(Landroid/content/Context;)Landroid/content/SharedPreferences;

    move-result-object v0

    if-eqz v0, :return

    invoke-interface {v0}, Landroid/content/SharedPreferences;->edit()Landroid/content/SharedPreferences$Editor;

    move-result-object v1

    const-string v2, "Pad1/Type"

    const-string v3, "DualShock2"

    invoke-static {v0, v1, v2, v3}, Lxyz/aethersx2/android/ThorHaptics;->putStringIfMissing(Landroid/content/SharedPreferences;Landroid/content/SharedPreferences$Editor;Ljava/lang/String;Ljava/lang/String;)Landroid/content/SharedPreferences$Editor;

    move-result-object v1

    const-string v2, "Pad1/LargeMotor"

    const-string v3, "__DEVICE_VIBRATOR__/Vibrator0"

    invoke-static {v0, v1, v2, v3}, Lxyz/aethersx2/android/ThorHaptics;->putStringIfMissing(Landroid/content/SharedPreferences;Landroid/content/SharedPreferences$Editor;Ljava/lang/String;Ljava/lang/String;)Landroid/content/SharedPreferences$Editor;

    move-result-object v1

    const-string v2, "Pad1/SmallMotor"

    const-string v3, "__DEVICE_VIBRATOR__/Vibrator0"

    invoke-static {v0, v1, v2, v3}, Lxyz/aethersx2/android/ThorHaptics;->putStringIfMissing(Landroid/content/SharedPreferences;Landroid/content/SharedPreferences$Editor;Ljava/lang/String;Ljava/lang/String;)Landroid/content/SharedPreferences$Editor;

    move-result-object v1

    const-string v2, "Pad1/LargeMotorScale"

    const/high16 v3, 0x3f800000    # 1.0f

    invoke-static {v0, v1, v2, v3}, Lxyz/aethersx2/android/ThorHaptics;->putFloatIfMissing(Landroid/content/SharedPreferences;Landroid/content/SharedPreferences$Editor;Ljava/lang/String;F)Landroid/content/SharedPreferences$Editor;

    move-result-object v1

    const-string v2, "Pad1/SmallMotorScale"

    const v3, 0x3eb33333    # 0.35f

    invoke-static {v0, v1, v2, v3}, Lxyz/aethersx2/android/ThorHaptics;->putFloatIfMissing(Landroid/content/SharedPreferences;Landroid/content/SharedPreferences$Editor;Ljava/lang/String;F)Landroid/content/SharedPreferences$Editor;

    move-result-object v1

    const-string v2, "TouchscreenController/EnableVibration"

    const/4 v3, 0x1

    invoke-static {v0, v1, v2, v3}, Lxyz/aethersx2/android/ThorHaptics;->putBooleanIfMissing(Landroid/content/SharedPreferences;Landroid/content/SharedPreferences$Editor;Ljava/lang/String;Z)Landroid/content/SharedPreferences$Editor;

    move-result-object v1

    const-string v2, "AndroidInputSource/VibrationThrottle"

    const/16 v3, 0x10

    invoke-static {v0, v1, v2, v3}, Lxyz/aethersx2/android/ThorHaptics;->putIntIfMissing(Landroid/content/SharedPreferences;Landroid/content/SharedPreferences$Editor;Ljava/lang/String;I)Landroid/content/SharedPreferences$Editor;

    move-result-object v1

    invoke-interface {v1}, Landroid/content/SharedPreferences$Editor;->apply()V

    const-string v0, "ThorHaptics"

    const-string v1, "Ensured Pad1 device-haptics motor defaults"

    invoke-static {v0, v1}, Landroid/util/Log;->i(Ljava/lang/String;Ljava/lang/String;)I
    :try_end_0
    .catch Ljava/lang/Exception; {:try_start_0 .. :try_end_0} :catch_0

    :return
    return-void

    :catch_0
    return-void
.end method

.method private static hasDeviceVibrator(Landroid/content/Context;)Z
    .locals 2

    const/4 v0, 0x0

    if-eqz p0, :return

    const-string v1, "vibrator"

    invoke-virtual {p0, v1}, Landroid/content/Context;->getSystemService(Ljava/lang/String;)Ljava/lang/Object;

    move-result-object p0

    check-cast p0, Landroid/os/Vibrator;

    if-eqz p0, :return

    invoke-virtual {p0}, Landroid/os/Vibrator;->hasVibrator()Z

    move-result v0

    :return
    return v0
.end method

.method private static mediaAttributes()Landroid/os/VibrationAttributes;
    .locals 2

    new-instance v0, Landroid/os/VibrationAttributes$Builder;

    invoke-direct {v0}, Landroid/os/VibrationAttributes$Builder;-><init>()V

    const/16 v1, 0x13

    invoke-virtual {v0, v1}, Landroid/os/VibrationAttributes$Builder;->setUsage(I)Landroid/os/VibrationAttributes$Builder;

    move-result-object v0

    invoke-virtual {v0}, Landroid/os/VibrationAttributes$Builder;->build()Landroid/os/VibrationAttributes;

    move-result-object v0

    return-object v0
.end method

.method private static putBooleanIfMissing(Landroid/content/SharedPreferences;Landroid/content/SharedPreferences$Editor;Ljava/lang/String;Z)Landroid/content/SharedPreferences$Editor;
    .locals 1

    invoke-interface {p0, p2}, Landroid/content/SharedPreferences;->contains(Ljava/lang/String;)Z

    move-result v0

    if-nez v0, :return

    invoke-interface {p1, p2, p3}, Landroid/content/SharedPreferences$Editor;->putBoolean(Ljava/lang/String;Z)Landroid/content/SharedPreferences$Editor;

    move-result-object p1

    :return
    return-object p1
.end method

.method private static putFloatIfMissing(Landroid/content/SharedPreferences;Landroid/content/SharedPreferences$Editor;Ljava/lang/String;F)Landroid/content/SharedPreferences$Editor;
    .locals 1

    invoke-interface {p0, p2}, Landroid/content/SharedPreferences;->contains(Ljava/lang/String;)Z

    move-result v0

    if-nez v0, :return

    invoke-interface {p1, p2, p3}, Landroid/content/SharedPreferences$Editor;->putFloat(Ljava/lang/String;F)Landroid/content/SharedPreferences$Editor;

    move-result-object p1

    :return
    return-object p1
.end method

.method private static putIntIfMissing(Landroid/content/SharedPreferences;Landroid/content/SharedPreferences$Editor;Ljava/lang/String;I)Landroid/content/SharedPreferences$Editor;
    .locals 1

    invoke-interface {p0, p2}, Landroid/content/SharedPreferences;->contains(Ljava/lang/String;)Z

    move-result v0

    if-nez v0, :return

    invoke-interface {p1, p2, p3}, Landroid/content/SharedPreferences$Editor;->putInt(Ljava/lang/String;I)Landroid/content/SharedPreferences$Editor;

    move-result-object p1

    :return
    return-object p1
.end method

.method private static putStringIfMissing(Landroid/content/SharedPreferences;Landroid/content/SharedPreferences$Editor;Ljava/lang/String;Ljava/lang/String;)Landroid/content/SharedPreferences$Editor;
    .locals 1

    invoke-interface {p0, p2}, Landroid/content/SharedPreferences;->contains(Ljava/lang/String;)Z

    move-result v0

    if-nez v0, :return

    invoke-interface {p1, p2, p3}, Landroid/content/SharedPreferences$Editor;->putString(Ljava/lang/String;Ljava/lang/String;)Landroid/content/SharedPreferences$Editor;

    move-result-object p1

    :return
    return-object p1
.end method

.method public static vibrate(Landroid/os/Vibrator;Landroid/os/VibrationEffect;)V
    .locals 2

    :try_start_0
    if-eqz p0, :return

    if-eqz p1, :return

    sget v0, Landroid/os/Build$VERSION;->SDK_INT:I

    const/16 v1, 0x1f

    if-lt v0, v1, :legacy

    invoke-static {}, Lxyz/aethersx2/android/ThorHaptics;->mediaAttributes()Landroid/os/VibrationAttributes;

    move-result-object v0

    invoke-virtual {p0, p1, v0}, Landroid/os/Vibrator;->vibrate(Landroid/os/VibrationEffect;Landroid/os/VibrationAttributes;)V

    goto :return

    :legacy
    invoke-virtual {p0, p1}, Landroid/os/Vibrator;->vibrate(Landroid/os/VibrationEffect;)V
    :try_end_0
    .catch Ljava/lang/Exception; {:try_start_0 .. :try_end_0} :catch_0

    :return
    return-void

    :catch_0
    return-void
.end method

.method public static vibrateCombined(Ljava/lang/Object;Landroid/os/CombinedVibration;)V
    .locals 2

    :try_start_0
    if-eqz p0, :return

    if-eqz p1, :return

    check-cast p0, Landroid/os/VibratorManager;

    sget v0, Landroid/os/Build$VERSION;->SDK_INT:I

    const/16 v1, 0x1f

    if-lt v0, v1, :legacy

    invoke-static {}, Lxyz/aethersx2/android/ThorHaptics;->mediaAttributes()Landroid/os/VibrationAttributes;

    move-result-object v0

    invoke-virtual {p0, p1, v0}, Landroid/os/VibratorManager;->vibrate(Landroid/os/CombinedVibration;Landroid/os/VibrationAttributes;)V

    goto :return

    :legacy
    invoke-virtual {p0, p1}, Landroid/os/VibratorManager;->vibrate(Landroid/os/CombinedVibration;)V
    :try_end_0
    .catch Ljava/lang/Exception; {:try_start_0 .. :try_end_0} :catch_0

    :return
    return-void

    :catch_0
    return-void
.end method
'@
[System.IO.File]::WriteAllText($helperPath, $helperSmali, $utf8NoBom)

function Add-ThorHapticsCall {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Missing smali file: $Path"
    }

    $text = Get-Content -LiteralPath $Path -Raw
    if ($text -match "Lxyz/aethersx2/android/ThorHaptics;->apply") {
        return
    }

    $pattern = "(\.method public final onCreate\(Landroid/os/Bundle;\)V\r?\n\s+\.locals \d+\r?\n)"
    $match = [regex]::Match($text, $pattern)
    if (-not $match.Success) {
        throw "Could not find onCreate method header in $Path"
    }

    $insert = "`r`n    invoke-static {p0}, Lxyz/aethersx2/android/ThorHaptics;->apply(Landroid/content/Context;)V`r`n"
    $updated = $text.Insert($match.Index + $match.Length, $insert)
    [System.IO.File]::WriteAllText($Path, $updated, $utf8NoBom)
}

Add-ThorHapticsCall -Path (Join-Path $targetDir "MainActivity.smali")
Add-ThorHapticsCall -Path (Join-Path $targetDir "EmulationActivity.smali")

function Update-VibrationCallPath {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        return
    }

    $text = Get-Content -LiteralPath $Path -Raw
    $text = $text.Replace(
        "invoke-virtual {p0, p1}, Landroid/os/Vibrator;->vibrate(Landroid/os/VibrationEffect;)V",
        "invoke-static {p0, p1}, Lxyz/aethersx2/android/ThorHaptics;->vibrate(Landroid/os/Vibrator;Landroid/os/VibrationEffect;)V"
    )
    $text = $text.Replace(
        "invoke-virtual {p2, p0}, Landroid/os/VibratorManager;->vibrate(Landroid/os/CombinedVibration;)V",
        "invoke-static {p2, p0}, Lxyz/aethersx2/android/ThorHaptics;->vibrateCombined(Ljava/lang/Object;Landroid/os/CombinedVibration;)V"
    )
    $text = $text.Replace(
        "invoke-virtual {p4, p0}, Landroid/os/VibratorManager;->vibrate(Landroid/os/CombinedVibration;)V",
        "invoke-static {p4, p0}, Lxyz/aethersx2/android/ThorHaptics;->vibrateCombined(Ljava/lang/Object;Landroid/os/CombinedVibration;)V"
    )
    [System.IO.File]::WriteAllText($Path, $text, $utf8NoBom)
}

Update-VibrationCallPath -Path (Join-Path $targetDir "NativeLibrary.smali")
Update-VibrationCallPath -Path (Join-Path $targetDir "InputBindingPreference.smali")

$touchPrefs = Join-Path $ProjectPath "res\xml\touchscreen_controller_preferences.xml"
if (Test-Path -LiteralPath $touchPrefs) {
    $text = Get-Content -LiteralPath $touchPrefs -Raw
    $replacement = '<SwitchPreferenceCompat app:defaultValue="true" app:iconSpaceReserved="false" app:key="TouchscreenController/EnableVibration" app:summary="@string/settings_summary_touchscreen_enable_vibration" app:title="@string/settings_touchscreen_enable_vibration" />'
    $text = [regex]::Replace($text, '<SwitchPreferenceCompat\b[^>]*app:key="TouchscreenController/EnableVibration"[^>]*/>', $replacement, 1)
    [System.IO.File]::WriteAllText($touchPrefs, $text, $utf8NoBom)
}

Write-Host "Patched Thor haptics defaults in $ProjectPath"
