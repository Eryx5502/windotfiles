# $Env:XDG_CONFIG_HOME = "$HOME\.config"
# $Env:KOMOREBI_CONFIG_HOME = "$Env:XDG_CONFIG_HOME\komorebi"
$env:TERM = "xterm-256color"
Set-Alias ls lsd
function la { lsd -la @args }
# fzf for history and file selector (lazy-loaded on first use)
$_loadPSFzf = {
    Remove-PSReadLineKeyHandler 'Ctrl+t'
    Remove-PSReadLineKeyHandler 'Ctrl+r'
    Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'
}
Set-PSReadLineKeyHandler -Chord 'Ctrl+t' -ScriptBlock { & $_loadPSFzf }
Set-PSReadLineKeyHandler -Chord 'Ctrl+r' -ScriptBlock { & $_loadPSFzf }
# Cache init scripts to avoid spawning processes on every startup.
# Run Refresh-ProfileCache to regenerate after updating fnm, starship, or zoxide.
$_cacheDir = "$HOME\.cache\pwsh-init"
if (-not (Test-Path "$_cacheDir\fnm.ps1")) {
    New-Item -ItemType Directory -Path $_cacheDir -Force | Out-Null
    fnm env --use-on-cd --shell powershell > "$_cacheDir\fnm.ps1"
    starship init powershell --print-full-init > "$_cacheDir\starship.ps1"
    zoxide init powershell > "$_cacheDir\zoxide.ps1"
}
. "$_cacheDir\fnm.ps1"
# Transient prompt (function must be defined before starship init)
function Invoke-Starship-TransientFunction { &starship module character }
. "$_cacheDir\starship.ps1"
Enable-TransientPrompt
. "$_cacheDir\zoxide.ps1"

# NOTE: After updating fnm, starship, or zoxide, run Refresh-ProfileCache and restart pwsh.
function Refresh-ProfileCache {
    fnm env --use-on-cd --shell powershell > "$_cacheDir\fnm.ps1"
    starship init powershell --print-full-init > "$_cacheDir\starship.ps1"
    zoxide init powershell > "$_cacheDir\zoxide.ps1"
    Write-Host "Profile cache refreshed. Restart pwsh to apply."
}
Set-Alias lg lazygit

# Load user scripts
. "$PSScriptRoot\Scripts\wezterm-edit.ps1"

#Variables
$dotnet = "D:\desarrollo\dotnet"
$javascript = "D:\desarrollo\javascript"

# Yazi file explorer (using y changes dir on exit, yazi won't)
function y {
    $tmp = (New-TemporaryFile).FullName
    yazi $args --cwd-file="$tmp"
    $cwd = Get-Content -Path $tmp -Encoding UTF8
    if (-not [String]::IsNullOrEmpty($cwd) -and $cwd -ne $PWD.Path) {
        Set-Location -LiteralPath (Resolve-Path -LiteralPath $cwd).Path
    }
    Remove-Item -Path $tmp
}

# Path for opencascade 3party
# $root = "D:\opencascade\3rdparty-vc14-64"
# $pathsToAdd = @()
#
# foreach ($subdir in Get-ChildItem $root -Directory) {
#     $binDir = Join-Path $subdir.FullName "bin"
#     $win64Dir = Join-Path $binDir "win64"
#
#     if (Test-Path $win64Dir) {
#         $pathsToAdd += $win64Dir
#     } elseif (Test-Path $binDir) {
#         $pathsToAdd += $binDir
#     }
# }
#
# $env:PATH += ";" + ($pathsToAdd -join ";")

# Load Visual Studio dev shell + castor env on demand (call Enter-VsDev when needed)
function vsdev {
    & 'C:\Program Files\Microsoft Visual Studio\18\Community\Common7\Tools\Launch-VsDevShell.ps1' -Arch amd64 -HostArch amd64
    cd -
}
function c {
  claude --dangerously-skip-permissions $args
}
