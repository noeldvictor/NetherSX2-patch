@echo off
set "apkdir=4248"
if not exist "%apkdir%\AndroidManifest.xml" if exist "NetherSX2\AndroidManifest.xml" set "apkdir=NetherSX2"
if not exist "%apkdir%\AndroidManifest.xml" (
  echo Error: could not find a decompiled APK folder named 4248 or NetherSX2.
  exit /b 1
)

:: --Manifest Cleanup--
lib\xml ed -L -d "manifest/uses-permission[@android:name='android.permission.ACCESS_NETWORK_STATE' or @android:name='com.google.android.gms.permission.AD_ID' or @android:name='android.permission.WAKE_LOCK' or @android:name='android.permission.FOREGROUND_SERVICE']" "%apkdir%\AndroidManifest.xml"
lib\xml ed -L -d "manifest/queries" "%apkdir%\AndroidManifest.xml"
lib\xml ed -L -d "manifest/application/service" "%apkdir%\AndroidManifest.xml"
lib\xml ed -L -d "manifest/application/receiver" "%apkdir%\AndroidManifest.xml"
lib\xml ed -L -d "manifest/application/meta-data[@android:name='com.google.android.gms.ads.APPLICATION_ID' or @android:name='com.google.android.gms.version']" "%apkdir%\AndroidManifest.xml"
lib\xml ed -L -d "manifest/application/provider/meta-data[@android:name='androidx.work.WorkManagerInitializer']" "%apkdir%\AndroidManifest.xml"
lib\xml ed -L -d "manifest/application/activity[@android:name='com.google.android.gms.ads.AdActivity' or @android:name='com.google.android.gms.version' or @android:name='com.google.android.gms.common.api.GoogleApiActivity' or @android:name='com.google.android.gms.ads.OutOfContextTestingActivity']" "%apkdir%\AndroidManifest.xml"
lib\xml ed -L -d "manifest/application/provider[@android:name='com.google.android.gms.ads.MobileAdsInitProvider']" "%apkdir%\AndroidManifest.xml"
lib\xml ed -L -d "manifest/application/activity/@android:preferMinimalPostProcessing" "%apkdir%\AndroidManifest.xml"
lib\xml ed -L -d "manifest/application/@android:extractNativeLibs" "%apkdir%\AndroidManifest.xml"

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0ApplyBrandingPatch.ps1" -ProjectPath "%apkdir%" -RepoRoot "%~dp0.."
if errorlevel 1 exit /b %errorlevel%
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0ApplyThorHapticsPatch.ps1" -ProjectPath "%apkdir%"
if errorlevel 1 exit /b %errorlevel%
:: --End Manifest Cleanup--

:: --Cheats UI Cleanup--
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0ApplyCheatUiPatch.ps1" -ProjectPath "%apkdir%"
if errorlevel 1 exit /b %errorlevel%
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0ApplyCheatBadgePatch.ps1" -ProjectPath "%apkdir%" -RepoRoot "%~dp0.."
if errorlevel 1 exit /b %errorlevel%
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0ApplyOsdCheatTogglePatch.ps1" -ProjectPath "%apkdir%"
if errorlevel 1 exit /b %errorlevel%
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0ApplyBundledCheatsPatch.ps1" -ProjectPath "%apkdir%" -RepoRoot "%~dp0.."
if errorlevel 1 exit /b %errorlevel%
:: --End Cheats UI Cleanup--

:: --Bundled Asset Updates--
if exist "%~dp0..\assets\faq.html" copy /Y "%~dp0..\assets\faq.html" "%apkdir%\assets\faq.html" >nul
if exist "%~dp0..\assets\cheats_index.html" copy /Y "%~dp0..\assets\cheats_index.html" "%apkdir%\assets\cheats_index.html" >nul
:: --End Bundled Asset Updates--

:: --Main Activity Layout Cleanup--
lib\xml ed -L -d "androidx.drawerlayout.widget.DrawerLayout/androidx.coordinatorlayout.widget.CoordinatorLayout/RelativeLayout/FrameLayout/@android:layout_above" "%apkdir%\res\layout\activity_main.xml"
lib\xml ed -L -d "androidx.drawerlayout.widget.DrawerLayout/androidx.coordinatorlayout.widget.CoordinatorLayout/RelativeLayout/FrameLayout/@android:layout_alignParentBottom" "%apkdir%\res\layout\activity_main.xml"
lib\xml ed -L -a "androidx.drawerlayout.widget.DrawerLayout/androidx.coordinatorlayout.widget.CoordinatorLayout/RelativeLayout/FrameLayout" -t attr -n "android:layout_alignParentBottom" -v "true" "%apkdir%\res\layout\activity_main.xml"
lib\xml ed -L -d "androidx.drawerlayout.widget.DrawerLayout/androidx.coordinatorlayout.widget.CoordinatorLayout/RelativeLayout/com.google.android.gms.ads.AdView" "%apkdir%\res\layout\activity_main.xml"
lib\xml ed -L -u "androidx.drawerlayout.widget.DrawerLayout/androidx.coordinatorlayout.widget.CoordinatorLayout/com.google.android.material.floatingactionbutton.FloatingActionButton/@android:layout_marginBottom" -v "16.0dip" "%apkdir%\res\layout\activity_main.xml"
:: --End Main Activity Layout Cleanup--

:: --Patch Native Library--
:: Patch signature checks
lib\hexalter "%apkdir%\lib\arm64-v8a\libemucore.so" 0x838560=0x66,0x00,0x00,0x14 0x83B324=0x62,0x00,0x00,0x14
:: Patch BIOS type check
lib\hexalter "%apkdir%\lib\arm64-v8a\libemucore.so" 0x829248=0x35,0x00,0x80,0x52

:: --Patch DEX--
if exist "%apkdir%\classes.dex" (
  :: Disable ads
  lib\hexalter "%apkdir%\classes.dex" 0x222264=0x0e,0x00 0x3C5B70=0x0e,0x00
  :: Restore Launcher support
  lib\hexalter "%apkdir%\classes.dex" 0x3BDAA4=0x12,0x11 0x3BDAAA=0x04 0x3BDAAD=0x05 0x3BDAB2=0x15
  lib\hexalter "%apkdir%\classes.dex" 0x3BDAA6=0x6e,0x10,0x93,0x02,0x02,0x00,0x0c,0x03,0x71,0x20,0xb3,0x90,0x13,0x00
  lib\hexalter "%apkdir%\classes.dex" 0x3BDAB4=0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00
  :: Fix checksum
  lib\hexalter "%apkdir%\classes.dex" 0x8=0xdd,0xa2,0x21,0x3a
) else (
  echo Skipping raw classes.dex hex patches; apktool decoded smali sources instead.
)
:: --End Patch Native Library--
