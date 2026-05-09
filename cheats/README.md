# Cheat Pack

This folder contains PNACH files for the Android app's visible external cheat folder.

- `exact/` is installed by default. Files are named by the exact NetherSX2 game CRC and contain real `patch=` lines, with every imported cheat disabled as `patch=0` so the OSD toggle dialog is the activation UI.
- `candidates/` is not installed by default. These files were copied from same-serial or nearby fan-translation PNACHs and need in-game testing before moving to `exact/`.

Install exact cheats to an attached Android device:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools\InstallCheatsToDevice.ps1
```

Install exact cheats plus candidate files for testing:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools\InstallCheatsToDevice.ps1 -IncludeCandidates
```

After pushing, the script runs `chmod 660` on `.pnach` files so the app can edit toggled cheat blocks.
