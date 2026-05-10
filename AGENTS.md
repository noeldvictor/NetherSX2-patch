# AGENTS.md

## Project Context

This repository is an APK patching workspace for NetherSX2, not a normal Gradle Android source tree. Most app changes are applied by replacing APK assets with `aapt` or by patching decoded APK resources through the scripts in `decomp/`.

## Cheat UI Work

- The in-app cheat controls are grouped by `decomp/ApplyCheatUiPatch.ps1`.
- The game list CHEATS badges are applied by `decomp/ApplyCheatBadgePatch.ps1`.
- The badge script generates `smali/xyz/aethersx2/android/CheatSupport.smali`, then patches the grid and list adapters to show a `cheat_badge` view only when a matching `.pnach` file in the visible external app `files/cheats` folder contains a real `patch=` code line. Do not use private internal app files, `assets/cheats_ws.zip`, or `assets/cheats_ni.zip` for the CHEATS badge; those are not user-visible real cheat availability.
- The OSD cheat toggle UI is patched by `decomp/ApplyOsdCheatTogglePatch.ps1`; it adds a root OSD `Toggle Cheat Codes` row directly above `Patch Codes`, and also keeps the same toggle dialog inside the `Patch Codes` submenu. The dialog opens a multi-choice list for the current game's `.pnach` and toggles each named cheat block individually by commenting/uncommenting its `patch=` lines. It normalizes enabled `patch=0,` lines to `patch=1,` so gameplay cheats apply every frame. It includes a non-closing `Deselect All` button and leaves an `Edit .pnach` fallback only when no cheat blocks can be parsed.
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
- Do not put explanatory `//` comments between a `[Cheats/... ]` header and its `patch=` lines; the OSD parser can display that comment as the toggle label. Keep PNACH research notes in `AGENTS.md` instead.
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

Tracked Markdown audit on 2026-05-10 covered `AGENTS.md`, `README.md`, `branding/README.md`, `cheats/README.md`, `cheats/candidates/README.md`, and `cheats/community/xs1l3n7x/README.md`. Ignore generated or scratch Markdown under `.tools`, `.tmp_*`, decoded APK folders, and temp directories unless the user explicitly asks to refresh generated docs.

## Branding Notes

The APK is branded as `NetherSX2 Thor Experiment`. Regenerate the launcher icons, setup-wizard logo, README banner, README fork button, and README wordmarks with:

```powershell
python tools\generate_brand_assets.py
```

The generated Android resources live under `branding/android/res`, README images live under `docs/assets`, and `decomp/ApplyBrandingPatch.ps1` copies Android resources into the decoded APK while updating the manifest labels and key English strings. `decomp/Hackify.bat` runs the branding patch before the cheat UI patches.

For the decompiled patch flow, run `decomp\Hackify.bat` after decoding the APK folder as either `4248` or `NetherSX2`; the script accepts both names. It applies the Cheats and Patches settings cleanup, game-list CHEATS badges, and OSD per-code cheat toggles. Rebuild and sign the APK after patching.

`decomp\Hackify.bat` also bundles the tracked PNACH packs into the APK via `assets/cheats_exact`; do not commit decoded APK folders just to capture those generated asset copies.

## Thor CPU/GPU Optimization Notes

Hardware assumptions checked on 2026-05-10:

- Thor Lite: Snapdragon 865 / Adreno 650. Do not assume Base/Pro/Max headroom; use native or 1.5x first, keep Turnip driver candidates A6xx-compatible, and be more willing to fall back to accurate rendering settings.
- Thor Base / Pro / Max / Max512: Snapdragon 8 Gen 2 / Adreno 740. Treat these as one CPU/GPU tuning bucket for NetherSX2. RAM/storage changes mostly affect multitasking, cache pressure, and how much media/library data fits locally rather than the emulator's raw EE/GS/VU throughput.

The checked target handheld reports `ro.product.model = AYN Thor`, `ro.board.platform = kalama`, `ro.soc.model = QCS8550`, `ro.hardware = qcom`, and Adreno EGL/Vulkan. This matches the Base/Pro/Max class, not Lite. It exposes three CPU clusters through cpufreq:

- policy0: little cores `0 1 2`
- policy3: big cores `3 4 5 6`
- policy7: prime core `7`

On 2026-05-10 the checked Thor had `performance_mode=0`, `fan_mode=4`, `peak_refresh_rate=60.0`, `min_refresh_rate=60.0`, and `Thermal Status: 0`. If performance is bad while `performance_mode=0`, first use the Thor quick settings/performance UI; plain ADB/app code should not blindly write unknown vendor performance values.

Good future app work is a Thor preset page or OSD quick-performance menu, not native thread surgery. Candidate Base/Pro/Max preset keys:

- `EmuCore/GS/Renderer = 14` for Vulkan
- `EmuCore/AffinityControlMode = 7` for Performance Cores
- `EmuCore/Speedhacks/vuThread = true` for MTVU on most 3D games
- `EmuCore/Speedhacks/vu1Instant = true`
- `EmuCore/CPU/Recompiler/EnableFastmem = true`
- `EmuCore/GS/HWDownloadMode = 1` for fast readbacks, with per-game fallback to `0` Accurate when effects/video/UI break
- `EmuCore/GS/accurate_blending_unit = 1` as the balanced default; use `0` only for a Fast preset
- `EmuCore/GS/upscale_multiplier = 1.500000` or `2.000000` as a sane Thor baseline, with per-game lowering before unsafe cycle skip

Preset shape:

- `Balanced`: Vulkan, Performance Cores, Fastmem, Instant VU1, MTVU, 1.5x or 2x, balanced blending, fast readbacks with per-game fallback to Accurate.
- `Fast`: Vulkan, Performance Cores, 1x or 1.5x, minimum/basic blending, fast readbacks, and no global 60 FPS or widescreen patches.
- `Accurate`: Vulkan or OpenGL per game, accurate readbacks, safer blending, and resolution reduction before EE cycle skip.
- `Lite Conservative`: same menu idea, but default to native or 1.5x, avoid Adreno 740-only driver assumptions, and expect more per-game fallbacks.

Avoid making global defaults out of 60 FPS patches, widescreen patches, EE cycle skip, or aggressive blending/readback hacks. They are per-game choices and can break timing or rendering.

## Custom GPU Driver Notes

`decomp\ApplyCustomGpuDriverPatch.ps1` adds a `Custom GPU Driver` row directly under `Settings > Graphics > GPU Renderer`. The row opens `xyz.aethersx2.android.GpuDriverManagerActivity`, which is compiled from `android-src/xyz/aethersx2/android/GpuDriverManagerActivity.java` into `classes2.dex` during patching.

The manager downloads a Turnip/AdrenoTools driver zip, extracts the Vulkan `.so`, renames it to `libvulkan_freedreno.so`, stores it under private app storage at `files/gpu_drivers/current`, writes an `enabled` marker, and sets `EmuCore/GS/Renderer = 14` for Vulkan. The pinned known-good download URL is K11MCH1's `Turnip_v26.0.0_R8.zip`, and the UI also allows a custom URL override.

The `Browse Turnip drivers` button fetches release assets directly from GitHub at runtime. Current curated sources are:

- `K11MCH1/AdrenoToolsDrivers`
- `StevenMXZ/Adreno-Tools-Drivers`
- `The412Banner/Banners-Turnip`
- `v3kt0r-87/Mesa-Turnip-Builder`

The catalog filters for Turnip/Mesa `.zip` or `.adpkg` packages and skips obvious Magisk/KSU modules, Android-version-incompatible releases, plus A8xx/Gen8/A710/A720-only packages for the checked Thor Base/Pro/Max Android 13 / Adreno 740 setup. If Lite support becomes an explicit target, keep regular A6xx-compatible candidates visible and do not filter purely around Adreno 740 assumptions. Each source is capped so one repo cannot crowd out the others. Keep the custom URL path available because driver recommendations move quickly and users may need a specific build before the curated list changes.

New installs also write an ADB-readable breadcrumb at:

```powershell
adb shell cat /sdcard/Android/data/xyz.aethersx2.android/files/gpu_driver_current.txt
```

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

The checked-in `decomp\lib\android.jks` uses store password `android_sign`, key alias `android_sign_alias`, and key password `android_sign_alias`. This matches the older patch scripts and the signed APKs currently installed on Thor.

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

For `Wizardry - Tale of the Forsaken Land (USA)`, the Thor inventory reports serial `SLUS-20259` and CRC `DD11BEF7`. The tracked exact PNACH is `cheats/exact/DD11BEF7.pnach`; it currently has money, stats, shop, spell-count, and experimental encounter blocks.

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

On 2026-05-09, Thor savestate slot 9 was captured with the monster warning active and slot 10 with no monster warning. The `.p2s` files used Zstandard-compressed zip entries, so install Python `zstandard` if the system zip reader cannot extract `eeMemory.bin`. The first low-risk diff candidate was byte `0048A038`, which was `04` in slot 9 and `00` in slot 10. Additional duplicated candidates were bytes `004892FD`, `004892FF`, `0048966D`, and `0048966F`, which were `0C` while the monster was close and `04` while calm.

- Rejected: `0048A038 = 00` did not stop or calm encounters in live play.
- Rejected: `004892FD`, `004892FF`, `0048966D`, and `0048966F` clamped to `04` caused camera issues, so this area is likely camera/dungeon-state adjacent rather than a safe encounter-rate control.
- Rejected: `00489668 = 00` also caused camera/control issues. Treat the whole `004896xx` cluster as camera/dungeon-control adjacent and do not use it for encounter cheats.

Ghidra/static notes from the same session:

- Extracted `SLUS_202.59` from the user's CHD and imported it into Ghidra using local Ghidra 12.0.4 and JDK 17. The main load segment maps file offset `0x1000` to EE address `0x00100000`, so runtime address = file offset + `0xFF000`.
- The global state byte at `005C1692` (`gp - 0x6B5E`) was `12` in Thor savestate slot 9 (red monster warning/imminent encounter) and `11` in slot 10 (post-battle/calm corridor). This is a better encounter-state signal than the rejected camera-adjacent `004896xx` values.
- Function `0011E318` handles the state-`11` encounter progression. After calls through `001BB570`, `0011DE70`, and `0017AA08`, instruction `0011E41C` branches to `0011E534`, which stores state `12` and begins the battle/warning setup. Original instruction word at `0011E41C` is `14400045` (`bnez v0,0011E534`).
- Rejected: NOPing only `0011E41C` stopped the battle transition after the encounter routine had already put the game into its pre-battle stop state. Do not use `patch=1,EE,2011E41C,extended,00000000` as the final no-encounter patch.
- Rejected: Replacing `0011E414` (`jal 0017AA08`) with `addiu v0,zero,0` prevented the battle handoff but still left the game on the black transition screen with white sparks, so the transition setup already happened before that point. Do not use `patch=1,EE,2011E414,extended,24020000` as the final no-encounter patch.
- Rejected: Replacing `0011E3EC` (`jal 0017AA38`) with `addiu v0,zero,0` removed the white sparks but still faded to a black screen after enemy contact. Do not use `patch=1,EE,2011E3EC,extended,24020000` as the final no-encounter patch.
- Rejected: Replacing `0011E3E4` (`jal 00100E90`) with an unconditional branch to the normal return still allowed enemy contact to begin a slow fade to black. Do not use `patch=1,EE,2011E3E4,extended,100000F9` as the final no-encounter patch.

- Rejected: Replacing `0011E5E4` (`jal 001E9150`) with `addiu v0,zero,0` did not stop battle start. Slot 8/9/10 savestate comparison explained why: `005C2B5E` is already `01` in slot 9 (red enemy/imminent) and slot 8 (in battle), and the original `001E9150` returns zero when that byte is `01`. Do not use `patch=1,EE,2011E5E4,extended,24020000` as the final no-encounter patch.

- Slot 8 was captured in battle after the failed contact-gate test. The key state comparison is:

```text
slot 10 post-battle/calm: 005C1692=11, 005C16A4=00000000, 005C2B5E=00
slot 9 red/imminent:      005C1692=12, 005C16A4=00006000, 005C2B5E=01
slot 8 in battle:         005C1692=12, 005C16A4=00002000, 005C2B5E=01
```

This means slot 9 is already past the initial trigger point. Tests that are meant to prevent the encounter must be loaded from slot 10 or a fresh calm dungeon state, not from slot 9 after `state=12`/`flags=0x6000` have already been set.

- The earlier trigger gate is at `0011E3B4`, which calls `001A9BA0`. In `0011E318`, if that call returns nonzero, the game sets bit `0x2000` in `005C16A4` and calls `00100E80`; later frames enter the state-`11`/state-`12` fade setup. `001A9BA0` has many callers, so patch only the `0011E3B4` callsite. Original instruction word at `0011E3B4` is `0C06A6E8`.

- Superseded test: the tracked PNACH previously had a default-off block named `No Random Encounters (Trigger Gate Test)`:

```ini
// patch=1,EE,2011E3B4,extended,24020000
```

It replaces the `0011E3B4` call with `addiu v0,zero,0`, leaving the delay-slot `nop` intact so the existing `beqz v0,0011E6F4` skips setting the `0x2000` encounter flag. This is a prevention patch, not a recovery patch; it will not unwind a state that already has `005C1692=12` or `005C16A4` bits `0x2000/0x4000` set.

- Deeper slot 10 -> slot 9 -> slot 8 static trace:
  - `001A9BA0` is the encounter predicate used by `0011E318`; it reads `004896CC`. Slot 10 has `004896CC=06000060`, while slots 9 and 8 have `004896CC=0E000000`. The raised bit is `0x08000000`.
  - `001A91E0` ORs `0x0C000000` into `004896CC` and then jumps to `001A9080`. That exactly explains slot 10 becoming slot 9 once low transient bits clear.
  - The only direct caller of `001A91E0` is `001BC3D8`, inside function `001BC280`. That function computes distance/angle against the current visible enemy struct at `*(gp - 0x6578)`, then calls `001A91E0`, `001E9180`, `00120108`, and `001097F8` to request the enemy encounter/warning flow.
  - The only direct caller of `001BC280` is `001B9468`, inside the 64-entry visible enemy update loop. The caller already skips `001BC280` when `004896CC & 0x08800000` is nonzero, which confirms this path is upstream of the visible-enemy encounter trigger rather than a late battle transition.
  - The current tracked candidate is therefore default-off:

```ini
[Cheats/No Enemy Encounters (Skip Visible Monster Contact Test)]
// patch=1,EE,201B9468,extended,00000000
```

This NOPs the `jal 001BC280` call before it can raise `004896CC |= 0x0C000000`, call `001E9180`, or enter the later state-`11`/state-`12` transition code. Test it from slot 10 or a fresh calm dungeon state. If a state already has `005C1692=12`, `005C16A4=0x2000/0x4000/0x6000`, or `004896CC & 0x08000000`, reload a pre-contact state; this patch prevents a new encounter request but does not unwind one that is already latched.

Do not re-add the rejected candidates to `cheats/exact/DD11BEF7.pnach`. If the `001B9468` contact-skip test fails, the next useful scan is a tighter caller trace around `001BC280`/`001E9180` and the visible enemy loop, not another blind clamp in the `004896xx` camera/control cluster.

## Cover Installer Notes

Use `tools\InstallCoversToDevice.ps1` to download covers for the games in `game_crc_index.tsv` and push them into the visible external app `files/covers` folder. It defaults to xlenore's documented 2D cover URL:

```powershell
https://raw.githubusercontent.com/xlenore/ps2-covers/main/covers/default/{serial}.jpg
```

The script must keep `-BaseUrl` override support. The template supports `{serial}`, `{crc}`, `{title}`, and `{ext}`; for example, xlenore 3D covers use:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools\InstallCoversToDevice.ps1 -BaseUrl 'https://raw.githubusercontent.com/xlenore/ps2-covers/main/covers/3d/{serial}.png'
```
