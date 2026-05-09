# AGENTS.md

## Project Context

This repository is an APK patching workspace for NetherSX2, not a normal Gradle Android source tree. Most app changes are applied by replacing APK assets with `aapt` or by patching decoded APK resources through the scripts in `decomp/`.

## Cheat UI Work

- The in-app cheat controls are grouped by `decomp/ApplyCheatUiPatch.ps1`.
- The game list CHEATS badges are applied by `decomp/ApplyCheatBadgePatch.ps1`.
- The badge script generates `smali/xyz/aethersx2/android/CheatSupport.smali`, then patches the grid and list adapters to show a `cheat_badge` view only when a matching `.pnach` file in the visible external app `files/cheats` folder contains a real `patch=` code line. Do not use private internal app files, `assets/cheats_ws.zip`, or `assets/cheats_ni.zip` for the CHEATS badge; those are not user-visible real cheat availability.
- The OSD Patch Codes menu is patched by `decomp/ApplyOsdCheatTogglePatch.ps1`; its `Toggle Cheat Codes` row opens a multi-choice dialog for the current game's `.pnach` and toggles each named cheat block individually by commenting/uncommenting its `patch=` lines. It normalizes enabled `patch=0,` lines to `patch=1,` so gameplay cheats apply every frame. It includes a non-closing `Deselect All` button and leaves an `Edit .pnach` fallback only when no cheat blocks can be parsed.
- The bundled default cheat pack is applied by `decomp/ApplyBundledCheatsPatch.ps1`. It copies tracked `cheats/community/xs1l3n7x/*.pnach` and `cheats/exact/*.pnach` into decoded APK `assets/cheats_exact`, with exact files overriding community files for duplicate CRCs. It generates `smali/xyz/aethersx2/android/BundledCheats.smali` and patches `MainActivity.onCreate` to seed missing external `files/cheats/*.pnach` files on startup. It must never overwrite non-empty existing device PNACH files, because those hold user toggle state.
- The OSD PNACH lookup should agree with the game-list badge lookup: use the native game PNACH path only when it exists and contains parsed cheat blocks, then recover the running `GameListEntry` from the game path and fall back to the visible external app `files/cheats/<GameListEntry CRC>.pnach` path before using the live game-info CRC.
- After pushing PNACH files with ADB, run `tools\FixCheatPermissions.ps1` so shell-owned cheat files become group-writable (`chmod 660`). The app should then edit them directly; do not add app-side ownership-repair save workarounds unless chmod cannot solve the target device.
- The OSD per-code cheat dialog must not toggle `EmuCore/EnableCheats`; that is a global app setting, not the per-cheat control.
- Individual cheat toggles still require the emulator's global/per-game `EmuCore/EnableCheats` gate to be enabled. If a selected cheat line is `patch=1,` and still has no effect, check that setting before assuming the PNACH failed.
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

## PNACH Timing Notes

- `patch=0,` is not disabled. In PCSX2 PNACH syntax it means apply only once at game startup, so many gameplay cheats will appear broken until a console reset, and even then only if the target value is not overwritten later by the game.
- `patch=1,` applies every frame and is the default for normal gameplay cheats such as health, money, VFX, inventory counts, and timers.
- Default-off tracked cheats should be stored as commented lines: `// patch=1,...`. The OSD toggle UI enables them by removing the comment and disables them by adding it back.
- Boot/unlock/event-style cheats may still need a game reset, area transition, save reload, or menu refresh even when the line is `patch=1,`; live stat cheats should not.
- The Viewtiful Joe 2 issue on Thor was caused by imported `patch=0,` lines. The fix was to convert repo cheats to `// patch=1,...`, normalize existing Thor files from `patch=0,` to `patch=1,`, and make `ApplyOsdCheatTogglePatch.ps1` normalize old enabled lines automatically.
- Do not reinstall the exact cheat pack just to fix timing on a user's device unless you intend to reset all per-cheat selections. `tools\InstallCheatsToDevice.ps1` pushes the repo baseline files, which are default-off, and can overwrite the user's current toggles.
- To preserve the user's current selected cheats on Thor while fixing timing, run a targeted in-place normalization like:

```powershell
adb shell "sed -i -E 's/^([[:space:]]*\/\/[[:space:]]*)?patch=0,/\1patch=1,/' /sdcard/Android/data/xyz.aethersx2.android/files/cheats/1B7DA82A.pnach"
```

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

`decomp\Hackify.bat` also bundles the tracked PNACH packs into the APK via `assets/cheats_exact`; do not commit decoded APK folders just to capture those generated asset copies.

## Custom GPU Driver Notes

`decomp\ApplyCustomGpuDriverPatch.ps1` adds a `Custom GPU Driver` row directly under `Settings > Graphics > GPU Renderer`. The row opens `xyz.aethersx2.android.GpuDriverManagerActivity`, which is compiled from `android-src/xyz/aethersx2/android/GpuDriverManagerActivity.java` into `classes2.dex` during patching.

The manager downloads a Turnip/AdrenoTools driver zip, extracts the Vulkan `.so`, renames it to `libvulkan_freedreno.so`, stores it under private app storage at `files/gpu_drivers/current`, writes an `enabled` marker, and sets `EmuCore/GS/Renderer = 14` for Vulkan. The default download URL is K11MCH1's `Turnip_v26.0.0_R8.zip`, and the UI also allows a custom URL override.

The native side is built by `tools\BuildGpuDriverShim.ps1`, which clones pinned `bylaws/libadrenotools` into ignored `.tools/libadrenotools`, builds arm64 libraries with the Android NDK, and copies these generated files into the decoded APK:

- `lib/arm64-v8a/libvulkad.so`
- `lib/arm64-v8a/libhook_impl.so`
- `lib/arm64-v8a/libmain_hook.so`

`ApplyCustomGpuDriverPatch.ps1` patches `lib/arm64-v8a/libemucore.so` strings from `libvulkan.so` to `libvulkad.so`. With no enabled marker or no installed driver, the shim falls back to the system Vulkan driver. Driver changes require a full emulator process restart, because Vulkan is loaded once per process. The shim logs to:

```powershell
adb shell cat /sdcard/Android/data/xyz.aethersx2.android/files/gpu_driver_shim.log
```

The generated native libs and libadrenotools checkout stay under `.tools/` and should not be committed. Commit the shim source, Java source, and patch scripts only.

Because the generated APK statically links BSD-licensed libadrenotools/linkernsbypass code into `libvulkad.so`, keep `third_party_notices/libadrenotools-BSD-2-Clause.txt` in the repo. `ApplyCustomGpuDriverPatch.ps1` copies it into APK assets at `assets/licenses/libadrenotools-BSD-2-Clause.txt`.

## Thor Haptics Notes

The AYN Thor exposes Android device haptics, not a normal dual-motor controller rumble device on the `Odin Controller` input device. `dumpsys input` shows the controller as gamepad/joystick only, while `dumpsys vibrator_manager` reports device vibrator id `0`.

`decomp\ApplyThorHapticsPatch.ps1` generates `smali/xyz/aethersx2/android/ThorHaptics.smali` and patches both `MainActivity.onCreate` and `EmulationActivity.onCreate` before native initialization. It also routes `NativeLibrary` and vibrator-binding test pulses through `VibrationAttributes.USAGE_MEDIA` on Android 12/API 31+ so game rumble goes through the media/game vibration path instead of the plain touch-feedback path. It seeds missing default preferences only when Android reports a device vibrator:

- `Pad1/Type = DualShock2`
- `Pad1/LargeMotor = __DEVICE_VIBRATOR__/Vibrator0`
- `Pad1/SmallMotor = __DEVICE_VIBRATOR__/Vibrator0`
- `Pad1/LargeMotorScale = 1.0`
- `Pad1/SmallMotorScale = 0.35`
- `TouchscreenController/EnableVibration = true`
- `AndroidInputSource/VibrationThrottle = 16`

This is a one-motor haptic fallback, not true DualShock2 dual-motor rumble. The helper uses `contains()` checks so existing user bindings are preserved; set an explicit blank/alternate value in the app if you do not want the defaults reseeded.

Thor can still ignore all vibration requests when Android's system vibration setting is off. During initial testing, `settings get system vibrate_on` returned `0`, and test pulses logged as `ignored_for_settings`; the installed test device was later set to `1`. Ensure it is enabled on the device UI or over ADB while testing:

```powershell
adb shell settings put system vibrate_on 1
adb shell settings put system haptic_feedback_enabled 1
```

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

Tracked PNACH files live under `cheats/exact` and `cheats/community/xs1l3n7x`; `cheats/exact` overrides duplicate community CRCs. Refresh the normalized community import with:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools\ImportPcsx2CheatsCollection.ps1 -Clean
```

Push tracked PNACH files with:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools\InstallCheatsToDevice.ps1
```

Use `-CommunityOnly` to refresh imported community PNACHs on a device without overwriting curated exact-file toggle state; it skips community files that duplicate `cheats/exact` CRCs.

Same-serial or fan-translation candidates live under `cheats/candidates`; install them only with `-IncludeCandidates` while actively testing in-game.

## Wizardry Encounter Research Notes

For `Wizardry - Tale of the Forsaken Land (USA)`, the Thor inventory reports serial `SLUS-20259` and CRC `DD11BEF7`. The tracked exact PNACH is `cheats/exact/DD11BEF7.pnach`; it currently has money, stats, shop, and spell-count blocks, but no known encounter-rate or no-random-encounter block.

Search notes from 2026-05-09:

- Japanese `BUSIN Wizardry Alternative` codes at `https://mutuki1406.moraimon.com/code/busin.html` cover `SLPM_620.98` and include money, shop, EXP/gold multipliers, spell-use, trust, HP/MP, job-change, and status-recovery codes. No clear `encounter`, `no encounter`, or lower encounter-rate code was found there.
- NTSC-U CodeBreaker codes at `https://www.almarsguides.com/retro/walkthroughs/ps2/games/wizardrytaleoftheforsakenland/codebreaker/` include the same general money, character, and shop families. No encounter code was found.
- GameHacking entry `https://gamehacking.org/?format=ar1&game=103061&hacker=all` did not expose an encounter code in the checked listing.

Plain ADB RAM inspection is blocked on the current Thor setup. `ro.debuggable` is `0`, `run-as xyz.aethersx2.android` fails because the APK is not debuggable, and no `su` binary is available to the shell user. Do not plan on reading `/proc/<pid>/mem` over plain ADB unless the APK is rebuilt debuggable, the device is rooted, or an app-side/native helper is deliberately added.

The practical no-root route is savestate RAM diffing. NetherSX2 `.p2s` files are zip archives containing `eeMemory.bin`, so two or three Wizardry states can be pulled and diffed offline:

```powershell
adb pull "/sdcard/Android/data/xyz.aethersx2.android/files/sstates/SLUS-20259 (DD11BEF7).00.p2s" tmp\wizardry_low.p2s
adb pull "/sdcard/Android/data/xyz.aethersx2.android/files/sstates/SLUS-20259 (DD11BEF7).01.p2s" tmp\wizardry_high.p2s
```

Ask the user to create slot 0 right after a battle or while encounter pressure feels low, then create slot 1 after walking until the next random battle feels close. A third state immediately after the encounter triggers or after the battle resets is useful for rejecting false positives. Extract `eeMemory.bin` with a normal zip reader, compare 8/16/32-bit little-endian values that change monotonically while walking and reset around battle entry, then test only the smallest plausible freeze or clamp in `cheats/exact/DD11BEF7.pnach` as default-off `// patch=1,...` lines. Promote the block only after it is verified in-game through the OSD toggle UI.

## Cover Installer Notes

Use `tools\InstallCoversToDevice.ps1` to download covers for the games in `game_crc_index.tsv` and push them into the visible external app `files/covers` folder. It defaults to xlenore's documented 2D cover URL:

```powershell
https://raw.githubusercontent.com/xlenore/ps2-covers/main/covers/default/{serial}.jpg
```

The script must keep `-BaseUrl` override support. The template supports `{serial}`, `{crc}`, `{title}`, and `{ext}`; for example, xlenore 3D covers use:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools\InstallCoversToDevice.ps1 -BaseUrl 'https://raw.githubusercontent.com/xlenore/ps2-covers/main/covers/3d/{serial}.png'
```
