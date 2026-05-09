param(
    [string]$RepoRoot = "",
    [string]$OutDir = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$libadrenotoolsCommit = "8fae8ce254dfc1344527e05301e43f37dea2df80"

if ([string]::IsNullOrWhiteSpace($RepoRoot)) {
    $RepoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..")).Path
}
$RepoRoot = (Resolve-Path -LiteralPath $RepoRoot).Path

if ([string]::IsNullOrWhiteSpace($OutDir)) {
    $OutDir = Join-Path $RepoRoot ".tools\gpu-driver-shim\arm64-v8a"
}

$androidSdk = $env:ANDROID_SDK_ROOT
if ([string]::IsNullOrWhiteSpace($androidSdk)) {
    $androidSdk = $env:ANDROID_HOME
}
if ([string]::IsNullOrWhiteSpace($androidSdk)) {
    $androidSdk = Join-Path $env:LOCALAPPDATA "Android\Sdk"
}
if (-not (Test-Path -LiteralPath $androidSdk)) {
    throw "Android SDK not found. Set ANDROID_SDK_ROOT or install Android SDK."
}

$ndkRoot = Join-Path $androidSdk "ndk"
$ndk = Get-ChildItem -LiteralPath $ndkRoot -Directory -ErrorAction Stop |
    Sort-Object Name -Descending |
    Select-Object -First 1
if ($null -eq $ndk) {
    throw "Android NDK not found under $ndkRoot."
}

$cmakeRoot = Join-Path $androidSdk "cmake"
$cmakeDir = Get-ChildItem -LiteralPath $cmakeRoot -Directory -ErrorAction Stop |
    Sort-Object Name -Descending |
    Select-Object -First 1
if ($null -eq $cmakeDir) {
    throw "Android SDK CMake not found under $cmakeRoot."
}

$cmake = Join-Path $cmakeDir.FullName "bin\cmake.exe"
$ninjaDir = Join-Path $cmakeDir.FullName "bin"
if (-not (Test-Path -LiteralPath $cmake)) {
    throw "Missing cmake executable: $cmake"
}

$toolsDir = Join-Path $RepoRoot ".tools"
$libDir = Join-Path $toolsDir "libadrenotools"
$buildDir = Join-Path $toolsDir "gpu-driver-shim-build"
[void](New-Item -ItemType Directory -Path $toolsDir -Force)

if (-not (Test-Path -LiteralPath (Join-Path $libDir ".git"))) {
    git clone https://github.com/bylaws/libadrenotools $libDir
}
git -C $libDir fetch --quiet origin $libadrenotoolsCommit
git -C $libDir checkout --quiet $libadrenotoolsCommit
git -C $libDir submodule update --init --recursive

[void](New-Item -ItemType Directory -Path $OutDir -Force)

$env:PATH = "$ninjaDir;$env:PATH"
$shimSource = Join-Path $RepoRoot "native\gpu-driver-shim"
$toolchainFile = Join-Path $ndk.FullName "build\cmake\android.toolchain.cmake"
$ninja = Join-Path $ninjaDir "ninja.exe"
& $cmake `
    -S $shimSource `
    -B $buildDir `
    -G Ninja `
    "-DADRENOTOOLS_DIR=$libDir" `
    "-DCMAKE_TOOLCHAIN_FILE=$toolchainFile" `
    "-DCMAKE_MAKE_PROGRAM=$ninja" `
    -DANDROID_ABI=arm64-v8a `
    -DANDROID_PLATFORM=android-26 `
    -DANDROID_STL=c++_static `
    -DCMAKE_BUILD_TYPE=Release
if ($LASTEXITCODE -ne 0) {
    throw "CMake configure failed."
}

& $cmake --build $buildDir --target vulkad hook_impl main_hook --config Release
if ($LASTEXITCODE -ne 0) {
    throw "CMake build failed."
}

$outputs = @(
    @{ Source = Join-Path $buildDir "libvulkad.so"; Name = "libvulkad.so" },
    @{ Source = Join-Path $buildDir "adrenotools-build\src\hook\libhook_impl.so"; Name = "libhook_impl.so" },
    @{ Source = Join-Path $buildDir "adrenotools-build\src\hook\libmain_hook.so"; Name = "libmain_hook.so" }
)

foreach ($item in $outputs) {
    if (-not (Test-Path -LiteralPath $item.Source)) {
        throw "Missing built native library: $($item.Source)"
    }
    Copy-Item -LiteralPath $item.Source -Destination (Join-Path $OutDir $item.Name) -Force
}

Write-Host "Built custom GPU driver shim libraries into $OutDir"
