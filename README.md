<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="/.github/assets/wordmark_dark.png">
    <img width="640" src="/.github/assets/wordmark_light.png" alt="NetherSX2 Patch Cheat Helper">
  </picture>
</p>

# NetherSX2 Patch Cheat Helper
This is a continuation of NetherSX2 to build on the amazing work already done by Anon and EZOnTheEyes

They aim to do the following:
* Brand the APK as NetherSX2 Cheat Helper with a custom Android launcher icon and setup-wizard logo
* Remove the unnecessary ad services bloat left in the apk
* Fix the RetroAchievements Notifications
* Expose more Global settings in the App Settings to the user
* Group cheat, widescreen, and no-interlacing toggles in a clearer in-app Cheats and Patches section
* Add an in-game OSD Patch Codes dialog that toggles individual `.pnach` cheat-code blocks, including a Deselect All action
* Mark games with visible external `.pnach` files containing real `patch=` cheat-code lines with a CHEATS badge
* Add an in-app FAQ link to a searchable list of games with bundled widescreen and no-interlacing patches
* Include an exact-CRC PNACH cheat pack and ADB install helper for the visible Android app cheats folder
* Add an ADB cover installer that defaults to xlenore's PS2 cover repository and supports custom cover URL templates
* Update the GameDB, Controller Support, and the Widescreen and No-Interlace Patches
* Add additional AetherSX2/NetherSX2 spesific fixes to the GameDB
* Resign the APK to Remove the Play Protect Warning

## Android Usability Helpers

Install the tracked exact-CRC cheat pack to an attached Android device:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools\InstallCheatsToDevice.ps1
```

Install covers for the games listed in `game_crc_index.tsv` using xlenore's default 2D cover URL:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools\InstallCoversToDevice.ps1
```

Use another cover source by overriding `-BaseUrl`. The template supports `{serial}`, `{crc}`, `{title}`, and `{ext}`:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools\InstallCoversToDevice.ps1 -BaseUrl 'https://raw.githubusercontent.com/xlenore/ps2-covers/main/covers/3d/{serial}.png'
```

## Installing NetherSX2
Once you've grabbed a copy of the [NetherSX2 APK](https://github.com/Trixarian/NetherSX2-patch/releases/download/2.1/NetherSX2-v2.1-4248.apk), it's time to install it on to your device

If you were using a copy of NetherSX2 1.9a or above: 
1. (Optional) Backup your files in case something goes wrong. The easiest method is to use the AetherSX2's built in Transfer Data function by using it's Export feature to move your files to an external folder. This will backup your bios files, memcards, save states, game settings, covers and texture packs
2. Install the apk normally to update to the latest version and keep your current settings

If you were using AetherSX2 or a copy of NetherSX2 older than 1.9a:
1. Backup your files. The easiest method is to use the AetherSX2's built in Transfer Data function by using it's Export feature to move your files to an external folder. This will backup your bios files, memcards, save states, game settings, covers and texture packs
2. After backing up your files, you need to remove any previous copies of AetherSX2 or NetherSX2. Do this by Uninstalling the app normally. Be sure NOT to keep any files if prompted
3. With the Backup and Uninstalls done, all that remains is to navigate to where you put your NetherSX2 apk with your File Manager (named Files or File Manager depending on your device) and tapping it to install it to your device
4. Once installed, run the app and configure it normally. Once at the Game List screen, you can access the Transfer Data/Backup Data feature and Import the files you exported earlier by navigating to the folder you put all your backed up files. This should import your bios files, memcards, save states, game settings, covers and texture packs
5. Now spend some time redoing the Global App Settings and you should be ready to go

## Frequently Asked Questions
### Why use NetherSX2 over AetherSX2?
Use NetherSX2 if you want:
* RetroArchievements
* Online Gaming Support
* Up to date configuration files
* No Ads (for AetherSX2 3036/4248 users)
* NetherSX2 spesific bug fixes for games
* Better controller support for automatic setup
* Have more control over your emulator via settings

### Which variant should I be using between Classic (3668) and Patched (4248)?
This largely depends on the games you will be playing. Generally Classic will be more performant - and some games will only function well on it like the Nascar ones - but it will be lacking some graphical and bug fixes only present in 4248. It's recommended to use 3668 with Mali or less powerful devices to get the best performance. For more powerful or Adreno devices, 4248 is the recommended variant to use

### What are the best settings for performance?
The default Optimal/Safe settings are the most compatible and performant for most games. You can further optimize them by using the Vulkan GPU renderer and setting Hardware Download Mode to Disable Readbacks. With 3668, also make sure to enable Threaded Presentation when using the Vulkan GPU renderer

## Downloads
### Stable
* [NetherSX2-v2.1-4248.apk](https://github.com/Trixarian/NetherSX2-patch/releases/download/2.1/NetherSX2-v2.1-4248.apk)

### Development Build
* [NetherSX2-v2.2n-4248.apk](https://github.com/Trixarian/NetherSX2-patch/releases/download/2.2n/NetherSX2-v2.2n-4248.apk)

## Credits
* PCSX2: <https://github.com/PCSX2/pcsx2> 
* EZOnTheEyes: <https://www.youtube.com/@EZOnTheEyes>
* Saramagrean: <https://github.com/Saramagrean/NetherSX2-cheats>
* Android Keystore: <https://github.com/jorfao/pkStore>
* SDL_GameControllerDB: <https://github.com/mdqinc/SDL_GameControllerDB>
