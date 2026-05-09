# AGENTS.md

## Project Context

This repository is an APK patching workspace for NetherSX2, not a normal Gradle Android source tree. Most app changes are applied by replacing APK assets with `aapt` or by patching decoded APK resources through the scripts in `decomp/`.

## Cheat UI Work

- The in-app cheat controls are grouped by `decomp/ApplyCheatUiPatch.ps1`.
- It keeps the existing emulator config keys:
  - `EmuCore/EnableCheats`
  - `EmuCore/EnableWideScreenPatches`
  - `EmuCore/EnableNoInterlacingPatches`
- Global settings use normal switches.
- Per-game settings use `xyz.aethersx2.android.TriStatePreference` so games can inherit, enable, or disable each setting.
- Regenerate `assets/cheats_index.html` after changing `assets/cheats_ws.zip` or `assets/cheats_ni.zip`:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools\GenerateCheatIndex.ps1
```

The FAQ links to `assets/cheats_index.html`, which gives the app an on-device list of games with bundled widescreen or no-interlacing patches.

## Local Tooling

- Java is required for `apktool.jar` and `apksigner.jar`.
- ADB is available from the scrcpy package on this machine:

```powershell
adb devices -l
```

- The AYN Thor should appear as `model:AYN_Thor`.

## Build Notes

Keep generated APKs, downloaded base APKs, portable JREs, and decoded APK folders out of commits. Commit source assets and patch scripts only.

For the decompiled patch flow, run `decomp\Hackify.bat` after decoding the APK folder as either `4248` or `NetherSX2`; the script accepts both names. Rebuild and sign the APK after patching.

For the asset-only patch flow, make sure `assets/cheats_index.html` is present before running `old/scripts/patch-apk.cmd` or `old/scripts/patch-apk.sh`; both scripts add it to the APK.

## ADB Install To AYN Thor

After building and signing an APK:

```powershell
adb devices -l
adb install -r path\to\NetherSX2.apk
```

If Android rejects a signature mismatch, uninstall the old package from the device first or install over a build signed with the same key.
