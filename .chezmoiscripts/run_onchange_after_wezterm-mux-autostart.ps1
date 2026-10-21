# Start wezterm-mux-server at sign-in so the GUI (default_gui_startup_args =
# connect unix) always finds a running server with its mux-startup workspaces.
#
# A Startup-folder shortcut needs no admin rights, unlike an AtLogOn scheduled
# task, and has no 72h execution time limit.

$exe = Join-Path $env:ProgramFiles 'WezTerm\wezterm-mux-server.exe'
if (-not (Test-Path $exe)) {
    Write-Host "wezterm-mux-server not found at $exe - skipping autostart shortcut."
    return
}

$lnk = Join-Path ([Environment]::GetFolderPath('Startup')) 'wezterm-mux-server.lnk'
$shortcut = (New-Object -ComObject WScript.Shell).CreateShortcut($lnk)
$shortcut.TargetPath = $exe
$shortcut.Arguments = '--daemonize'
$shortcut.WindowStyle = 7
$shortcut.Save()
Write-Host "WezTerm mux server autostart shortcut written to $lnk"
