# fix-hunk.ps1
# Re-applies the two local workarounds that make hunkdiff launch and render
# correctly on Windows. Run this AFTER a fresh `npm i -g hunkdiff` (a reinstall
# overwrites the package folder and undoes both fixes).
#
# TIP: after installing/updating hunkdiff, just run `hunk` first. If a newer
# release fixed the launch bug, you don't need this script. Only run it if hunk
# errors with "error code 126" or renders with a pink/magenta color cast.
#
# Safe to re-run. It works for whichever Node is currently active (fnm-aware).

$ErrorActionPreference = 'Stop'

# 1) Locate the global hunkdiff install for the currently-active Node
$root = (npm root -g).Trim()
$pkg  = Join-Path $root 'hunkdiff'
if (-not (Test-Path $pkg)) { throw "hunkdiff not found under $root - install it for the active Node first." }
Write-Host "hunkdiff: $pkg"

# 2) Disable the broken prebuilt exe so the launcher uses the `bun main.js` fallback
$exe = Join-Path $pkg 'node_modules\hunkdiff-windows-x64\bin\hunk.exe'
if (Test-Path $exe) {
  Rename-Item -Force $exe "$exe.disabled-bunfs-dlopen"
  Write-Host "[1/2] Disabled broken prebuilt hunk.exe (forces bun main.js fallback)"
} else {
  Write-Host "[1/2] Prebuilt hunk.exe already absent/disabled - skipping"
}

# 3) Match the native OpenTUI DLL to the version bundled inside main.js
$main = Join-Path $pkg 'dist\npm\main.js'
$content = Get-Content $main -Raw
if ($content -notmatch '@opentui/react",\s*version:\s*"([0-9.]+)"') {
  throw "Could not read the bundled OpenTUI version from main.js"
}
$ver = $Matches[1]
Write-Host "      Bundled OpenTUI version: $ver"

$dll = Join-Path $pkg 'node_modules\@opentui\core-win32-x64\opentui.dll'

$tmp = Join-Path $env:TEMP ("otui-" + $ver + "-" + $PID)
Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force $tmp | Out-Null
Push-Location $tmp
try {
  npm pack "@opentui/core-win32-x64@$ver" 2>&1 | Out-Null
  $tgz = Get-ChildItem *.tgz | Select-Object -First 1
  tar -xzf $tgz.Name
} finally { Pop-Location }

$src = Join-Path $tmp 'package\opentui.dll'
if (-not (Test-Path $src)) { throw "Downloaded @opentui/core-win32-x64@$ver has no opentui.dll" }

if (-not (Test-Path "$dll.bak-original")) { Copy-Item $dll "$dll.bak-original" }
Copy-Item -Force $src $dll
Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue
Write-Host "[2/2] Swapped opentui.dll -> $ver (matches the bundled JS)"

Write-Host "`nDone. Run 'hunk' to verify: it should launch, and diffs should be"
Write-Host "dark-gray background with green additions / red deletions (no pink)."
