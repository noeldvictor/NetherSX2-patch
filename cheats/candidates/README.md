# Candidate PNACH Files

These files are intentionally not installed by default.

They were renamed to the user's current NetherSX2 CRCs from same-serial or nearby fan-translation PNACH files. They may load, but they need in-game testing before they should affect the cover `CHEATS` badge.

Install them only while testing:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools\InstallCheatsToDevice.ps1 -IncludeCandidates
```

If a candidate works in-game, move it to `cheats\exact` and keep all `patch=` lines disabled by commenting them as `// patch=1,...`.
