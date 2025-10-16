$Env:XDG_CONFIG_HOME = "$HOME\.config"
$Env:KOMOREBI_CONFIG_HOME = "$Env:XDG_CONFIG_HOME\komorebi"
$env:TERM = "xterm-256color"
Import-Module -Name Terminal-Icons
# fzf for history and file selector
Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'
# Node fnm manager
fnm env --use-on-cd --shell powershell | Out-String | Invoke-Expression
# oh-my-posh
oh-my-posh init pwsh --config "~/.config/ohmyposh.omp.json" | Invoke-Expression
Invoke-Expression (& { (zoxide init powershell | Out-String) })
Set-Alias lg lazygit

#Variables
$dotnet = "D:\desarrollo\dotnet"
$javascript = "D:\desarrollo\javascript"
# Path for opencascade 3party
$root = "D:\opencascade\3rdparty-vc14-64"
$pathsToAdd = @()

foreach ($subdir in Get-ChildItem $root -Directory) {
    $binDir = Join-Path $subdir.FullName "bin"
    $win64Dir = Join-Path $binDir "win64"

    if (Test-Path $win64Dir) {
        $pathsToAdd += $win64Dir
    } elseif (Test-Path $binDir) {
        $pathsToAdd += $binDir
    }
}

$env:PATH += ";" + ($pathsToAdd -join ";")
