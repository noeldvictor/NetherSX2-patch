# AGENTS.md

## Project Context

This repository is an APK patching workspace for NetherSX2, not a normal Gradle Android source tree. Most app changes are applied by replacing APK assets with `aapt` or by patching decoded APK resources through the scripts in `decomp/`.

## Cheat UI Work

- The in-app cheat controls are grouped by `decomp/ApplyCheatUiPatch.ps1`.
- The game list CHEATS badges are applied by `decomp/ApplyCheatBadgePatch.ps1`.
- The badge script generates `smali/xyz/aethersx2/android/CheatSupport.smali`, then patches the grid and list adapters to show a `cheat_badge` view only when a matching `.pnach` file in the visible external app `files/cheats` folder contains a real `patch=` code line. Do not use private internal app files, `assets/cheats_ws.zip`, or `assets/cheats_ni.zip` for the CHEATS badge; those are not user-visible real cheat availability.
- The OSD Patch Codes menu is patched by `decomp/ApplyOsdCheatTogglePatch.ps1`; its `Toggle Cheat Codes` row opens a multi-choice dialog for the current game's `.pnach` and toggles each named cheat block individually by commenting/uncommenting its `patch=` lines. It normalizes enabled `patch=0,` lines to `patch=1,` so gameplay cheats apply every frame. It includes a non-closing `Deselect All` button and leaves an `Edit .pnach` fallback only when no cheat blocks can be parsed.
- The OSD PNACH lookup should agree with the game-list badge lookup: use the native game PNACH path only when it exists and contains parsed cheat blocks, then recover the running `GameListEntry` from the game path and fall back to the visible external app `files/cheats/<GameListEntry CRC>.pnach` path before using the live game-info CRC.
- After pushing PNACH files with ADB, run `tools\FixCheatPermissions.ps1` so shell-owned cheat files become group-writable (`chmod 660`). The app should then edit them directly; do not add app-side ownership-repair save workarounds unless chmod cannot solve the target device.
- The OSD per-code cheat dialog must not toggle `EmuCore/EnableCheats`; that is a global app setting, not the per-cheat control.
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

## Branding Notes

The APK is branded as `NetherSX2 Cheat Helper`. Regenerate the launcher icons, setup-wizard logo, and README wordmarks with:

```powershell
python tools\generate_brand_assets.py
```

The generated Android resources live under `branding/android/res`, and `decomp/ApplyBrandingPatch.ps1` copies them into the decoded APK while updating the manifest labels and key English strings. `decomp/Hackify.bat` runs the branding patch before the cheat UI patches.

For the decompiled patch flow, run `decomp\Hackify.bat` after decoding the APK folder as either `4248` or `NetherSX2`; the script accepts both names. It applies the Cheats and Patches settings cleanup, game-list CHEATS badges, and OSD per-code cheat toggles. Rebuild and sign the APK after patching.

Before signing an APK for Android 11+ devices, run `zipalign -p -f 4` on the unsigned APK, then sign the aligned APK with `apksigner`. Otherwise Android can reject the install because `resources.arsc` is not 4-byte aligned.

For the asset-only patch flow, make sure `assets/cheats_index.html` is present before running `old/scripts/patch-apk.cmd` or `old/scripts/patch-apk.sh`; both scripts add it to the APK.

## ADB Install To AYN Thor

After building and signing an APK:

```powershell
adb devices -l
adb install -r path\to\NetherSX2.apk
```

If Android rejects a signature mismatch, uninstall the old package from the device first or install over a build signed with the same key.

After pushing cheat PNACH files to the Thor:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools\FixCheatPermissions.ps1
```

## ADB Cheat Inventory Notes

When checking which games truly have cheats on the AYN Thor, use the emulator's game CRC as the source of truth. Do not infer cheat availability from ROM filenames, cover filenames, serial-only matches, widescreen patches, 60 FPS patches, or no-interlacing patches.

The temporary CRC inventory export writes this untracked file in external app storage:

```powershell
adb pull /sdcard/Android/data/xyz.aethersx2.android/files/game_crc_index.tsv .\game_crc_index.tsv
```

Match `game_crc_index.tsv` against visible external files in `/sdcard/Android/data/xyz.aethersx2.android/files/cheats/<CRC>.pnach`, and count only files with real `patch=` lines. If importing PNACH files from an external cheat pack, prefer exact CRC matches, remove enhancement-only blocks such as widescreen or 60 FPS, and keep gameplay cheats as `patch=1,` every-frame lines unless a source explicitly needs another timing. Default-disabled cheats should be commented as `// patch=1,...`; do not use `patch=0` as a disabled state because in PNACH syntax it means apply only at game startup.

Tracked PNACH files live under `cheats/exact` and can be pushed with:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools\InstallCheatsToDevice.ps1
```

Same-serial or fan-translation candidates live under `cheats/candidates`; install them only with `-IncludeCandidates` while actively testing in-game.

## Cover Installer Notes

Use `tools\InstallCoversToDevice.ps1` to download covers for the games in `game_crc_index.tsv` and push them into the visible external app `files/covers` folder. It defaults to xlenore's documented 2D cover URL:

```powershell
https://raw.githubusercontent.com/xlenore/ps2-covers/main/covers/default/{serial}.jpg
```

The script must keep `-BaseUrl` override support. The template supports `{serial}`, `{crc}`, `{title}`, and `{ext}`; for example, xlenore 3D covers use:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools\InstallCoversToDevice.ps1 -BaseUrl 'https://raw.githubusercontent.com/xlenore/ps2-covers/main/covers/3d/{serial}.png'
```
