# Launcher used by yazi's `e` keybinding.
# yazi can't call the `e` PowerShell function directly, so we dot-source the
# profile (skipped by -NoProfile) to define `e`, then hand it the file paths.
param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Paths
)

. $PROFILE

if ($Paths) {
    e @Paths
}
