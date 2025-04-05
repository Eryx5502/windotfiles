$Env:KOMOREBI_CONFIG_HOME = 'C:\Users\aitor\.config\komorebi'
Import-Module -Name Terminal-Icons
# fzf for history and file selector
Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'
# Node fnm manager
fnm env --use-on-cd --shell powershell | Out-String | Invoke-Expression
# oh-my-posh
Invoke-Expression (& { (zoxide init powershell | Out-String) })
oh-my-posh init pwsh --config "~/.config/ohmyposh.omp.json" | Invoke-Expression
