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
