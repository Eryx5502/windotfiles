# ssh-copy-id for PowerShell, targeting both Unix and Windows sshd.
#
# Git for Windows ships the real thing at usr\bin\ssh-copy-id, but it is a POSIX
# shell script that sends `exec sh -c '<umask/mkdir/chmod/cat/restorecon>'` to the
# remote. That is dead on arrival against a Windows sshd: its default shell is
# cmd.exe, where `exec` is not a command and none of those tools exist. It also
# knows nothing about administrators_authorized_keys. Hence this reimplementation.

function Copy-SshKey {
    <#
    .SYNOPSIS
        Installs a public key into a remote host's authorized_keys, on Unix or Windows.

    .EXAMPLE
        Copy-SshKey user@host
    .EXAMPLE
        ssh-copy-id -i ~\.ssh\id_rsa user@host -p 2222
    .EXAMPLE
        ssh-copy-id user@host -WhatIf     # print the payloads, contact nothing
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Target,

        # These aliases are explicit rather than relying on PowerShell's prefix
        # matching: [CmdletBinding()] injects -InformationAction/-InformationVariable
        # and -PipelineVariable/-ProgressAction, so bare -i and -p would otherwise
        # bind ambiguously and throw.
        [Alias('i')]
        [string]$Identity,

        [Alias('p')]
        [int]$Port,

        [Alias('f')]
        [switch]$Force,

        [ValidateSet('Auto', 'Unix', 'Windows')]
        [string]$RemoteOS = 'Auto'
    )

    # --- resolve the public key ------------------------------------------------
    $sshDir = Join-Path $HOME '.ssh'
    if ($Identity) {
        $path = [Environment]::ExpandEnvironmentVariables($Identity)
        # Accept the private-key path too, the way upstream does.
        if ($path -notmatch '\.pub$') { $path = "$path.pub" }
        if (-not (Test-Path -LiteralPath $path)) { throw "Public key not found: $path" }
        $keyPath = (Resolve-Path -LiteralPath $path).Path
    }
    else {
        $default = Join-Path $sshDir 'id_ed25519.pub'
        if (Test-Path -LiteralPath $default) {
            $keyPath = $default
        }
        else {
            $found = @(Get-ChildItem -LiteralPath $sshDir -Filter 'id_*.pub' -File -ErrorAction Ignore |
                Where-Object { $_.Name -notlike '*-cert.pub' })
            if ($found.Count -eq 1) { $keyPath = $found[0].FullName }
            elseif ($found.Count -eq 0) { throw "No public key in $sshDir. Generate one with: ssh-keygen -t ed25519" }
            else { throw "Several keys in ${sshDir}: $($found.Name -join ', '). Pick one with -i." }
        }
    }

    $lines = @(Get-Content -LiteralPath $keyPath | Where-Object { $_.Trim() })
    if ($lines.Count -ne 1) { throw "$keyPath should hold exactly one key line, found $($lines.Count)." }
    $key = $lines[0].Trim()

    if ($key -match 'PRIVATE KEY') {
        throw "$keyPath looks like a PRIVATE key. Refusing to send it - point -i at the .pub file."
    }
    if ($key -notmatch '^(ssh-|ecdsa-|sk-)\S+\s+\S+') {
        throw "$keyPath does not look like an OpenSSH public key."
    }
    # The key is embedded in a single-quoted remote command below. An apostrophe in
    # the comment would need `'\''`, and backslashes are the one thing that does not
    # survive PowerShell -> MSYS ssh.exe argument parsing predictably. Rare enough to
    # refuse rather than guess at.
    if ($key.Contains("'")) {
        throw "The key comment in $keyPath contains an apostrophe, which cannot be quoted safely. Re-comment it with: ssh-keygen -c -f $($keyPath -replace '\.pub$')"
    }

    $sshArgs = @()
    if ($PSBoundParameters.ContainsKey('Port')) { $sshArgs += @('-p', "$Port") }
    $sshArgs += $Target

    # --- Unix payload ----------------------------------------------------------
    # The key is embedded rather than piped on stdin: PowerShell terminates a native
    # pipe with CRLF, which would leave a trailing CR in authorized_keys and break
    # both the duplicate check and the key itself.
    # Only `;`, `&&`, `||` and `( )` are used, so this also survives a csh remote -
    # which is what upstream needs its `exec sh -c` wrapper for.
    $A = '.ssh/authorized_keys'
    # `cd || exit 1` matters: if the home directory is missing, an unguarded `cd`
    # leaves everything after it writing .ssh/authorized_keys relative to whatever
    # the session's cwd happens to be, and still echoing the success marker.
    # restorecon is not optional on SELinux distros (RHEL/Rocky/Alma/Fedora): a .ssh
    # created from scratch here lands with context user_home_t instead of ssh_home_t,
    # and sshd then refuses to read authorized_keys without saying so - the file looks
    # perfect and you still get a password prompt. `type` guards hosts without it.
    $prologue = "umask 077 ; cd || exit 1 ; mkdir -p .ssh ; chmod 700 .ssh ; touch $A ; chmod 600 $A ; " +
                "type restorecon >/dev/null 2>&1 && restorecon -F .ssh $A ; "
    # The bare `echo` guards an authorized_keys with no trailing newline, which would
    # otherwise splice two keys into one broken line. sshd ignores the blank line it
    # may leave behind.
    if ($Force) {
        $unixCmd = $prologue + "echo >> $A ; echo '$key' >> $A ; echo COPYKEY_ADDED"
    }
    else {
        $append = "( echo >> $A ; echo '$key' >> $A ; echo COPYKEY_ADDED )"
        $unixCmd = $prologue + "grep -qxF '$key' $A && echo COPYKEY_ALREADY || $append"
    }

    # --- Windows payload -------------------------------------------------------
    # Sent as -EncodedCommand (UTF-16LE base64) so cmd.exe, which is the default
    # shell for Windows sshd, never has to quote any of it.
    $winTemplate = @'
$ErrorActionPreference = 'Stop'
$key = '__KEY__'
$force = $__FORCE__

# sshd's stock config routes Administrators-group users to a separate file via
# `Match Group administrators`. That matches on GROUP MEMBERSHIP, not elevation, so
# test for the SID in the token's groups: IsInRole(Administrator) answers $false for
# a UAC-filtered admin token and would send the key to a file sshd never reads.
$id = [Security.Principal.WindowsIdentity]::GetCurrent()
$inAdmins = $id.Groups -contains [Security.Principal.SecurityIdentifier]'S-1-5-32-544'

if ($inAdmins) {
    $file = Join-Path $env:ProgramData 'ssh\administrators_authorized_keys'
    $grants = @('*S-1-5-18:F', '*S-1-5-32-544:F')
}
else {
    $dir = Join-Path $env:USERPROFILE '.ssh'
    if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    $file = Join-Path $dir 'authorized_keys'
    $grants = @('*S-1-5-18:F', '*S-1-5-32-544:F', ('*' + $id.User.Value + ':F'))
}

try {
    if (-not (Test-Path -LiteralPath $file)) { New-Item -ItemType File -Path $file -Force | Out-Null }
    $existing = @(Get-Content -LiteralPath $file -ErrorAction SilentlyContinue | ForEach-Object { $_.Trim() })
    if (-not $force -and $existing -contains $key) {
        $result = 'COPYKEY_ALREADY'
    }
    else {
        # Windows PowerShell 5.1 -- what sshd hosts almost always run -- writes a BOM
        # for `-Encoding utf8`, and a BOM makes sshd fail to parse the first key.
        $enc = New-Object System.Text.UTF8Encoding($false)
        $prefix = ''
        if ((Get-Item -LiteralPath $file).Length -gt 0) { $prefix = "`r`n" }
        [IO.File]::AppendAllText($file, $prefix + $key + "`r`n", $enc)
        $result = 'COPYKEY_ADDED'
    }
}
catch [UnauthorizedAccessException] {
    Write-Output ('COPYKEY_DENIED ' + $file)
    exit 3
}

# chmod means nothing here; sshd checks the ACL instead. Grant by SID, never by name -
# 'BUILTIN\Administrators' is localised on non-English Windows.
& icacls.exe @(@($file, '/inheritance:r') + ($grants | ForEach-Object { '/grant', $_ })) 2>&1 | Out-Null
Write-Output $result
'@

    $winScript = $winTemplate.Replace('__KEY__', $key).Replace('__FORCE__', $(if ($Force) { 'true' } else { 'false' }))
    $b64 = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($winScript))

    if (-not $PSCmdlet.ShouldProcess($Target, "install $(Split-Path -Leaf $keyPath)")) {
        Write-Host "`n--- Unix payload ---`n$unixCmd" -ForegroundColor DarkCyan
        Write-Host "`n--- Windows payload (sent base64-encoded) ---`n$winScript" -ForegroundColor DarkCyan
        return
    }

    # --- run -------------------------------------------------------------------
    # Optimistic: every connection costs a password prompt while key auth is not yet
    # set up, so no probe round trip. The Unix payload echoes a marker on success;
    # no marker means the remote is not POSIX, so retry as Windows. A Windows box
    # writes nothing during the failed first attempt - cmd.exe cannot run `umask`,
    # and `;` is an argument delimiter there, not a command separator.
    # stderr is folded in with 2>&1 so a failure can quote the remote's own complaint
    # back to the user - without it the error below says only "it did not work".
    $text = ''
    $unixOut = $null
    $winOut = $null
    if ($RemoteOS -in 'Auto', 'Unix') {
        Write-Verbose "Trying the Unix payload against $Target"
        $unixOut = (& ssh @sshArgs $unixCmd 2>&1 | Out-String)
        Write-Verbose "Unix attempt exit $LASTEXITCODE, output: $($unixOut.Trim())"
        $text = $unixOut
    }
    if ($text -notmatch 'COPYKEY_(ADDED|ALREADY)' -and $RemoteOS -in 'Auto', 'Windows') {
        if ($RemoteOS -eq 'Auto') { Write-Verbose 'No marker back; assuming a Windows sshd.' }
        $winOut = (& ssh @sshArgs powershell -NoProfile -NonInteractive -EncodedCommand $b64 2>&1 | Out-String)
        Write-Verbose "Windows attempt exit $LASTEXITCODE, output: $($winOut.Trim())"
        $text = $winOut
    }

    $hint = "ssh $(if ($PSBoundParameters.ContainsKey('Port')) { "-p $Port " })$Target"
    if ($text -match 'COPYKEY_ADDED') {
        Write-Host "Added $(Split-Path -Leaf $keyPath) to $Target" -ForegroundColor Green
        Write-Host "Now try:  $hint"
    }
    elseif ($text -match 'COPYKEY_ALREADY') {
        Write-Warning "Key already present on $Target - nothing to do. Use -Force to append it anyway."
    }
    elseif ($text -match 'COPYKEY_DENIED\s+(\S.*)') {
        $f = $Matches[1].Trim()
        Write-Error @"
Access denied writing $f on $Target.
The account is in the Administrators group, so sshd reads that file, but this SSH
session's token is not elevated. Run this in an ELEVATED PowerShell on ${Target}:
    Add-Content -Path '$f' -Value '$key'
    icacls '$f' /inheritance:r /grant *S-1-5-18:F /grant *S-1-5-32-544:F
"@
    }
    else {
        $why = @()
        foreach ($a in @(@{ n = 'Unix'; o = $unixOut }, @{ n = 'Windows'; o = $winOut })) {
            if ($null -ne $a.o) {
                $lines = @($a.o -split "`r?`n" | Where-Object { $_.Trim() } | Select-Object -Last 4)
                $why += "  $($a.n) attempt: " + $(if ($lines) { ($lines -join "`n    ") } else { '(no output at all)' })
            }
        }
        Write-Error (@(
                "Could not install the key on $Target - no success marker came back."
                ($why -join "`n")
                "Pin the remote type with -RemoteOS Unix|Windows to see one attempt on its own,"
                "and check the remote by hand with:  ssh $Target 'echo MARKER; uname -s'"
            ) -join "`n")
    }
}

Set-Alias ssh-copy-id Copy-SshKey
