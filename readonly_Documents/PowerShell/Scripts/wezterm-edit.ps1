# Open text files in nvim inside the current wezterm window.
#   e <file>...              -> new tab (default)
#   e -Right <file>...       -> vertical split (pane on the right)
#   e -Down  <file>...       -> horizontal split (pane on the bottom)
#   e -Percent 40 -Right f   -> split sized to 40% of the parent
#   e -Editor code f.md      -> override editor (default: nvim)
function e {
    [CmdletBinding(DefaultParameterSetName = 'Tab')]
    param(
        [Parameter(ParameterSetName = 'SplitRight')][switch]$Right,
        [Parameter(ParameterSetName = 'SplitDown')][switch]$Down,
        [int]$Percent,
        [string]$Editor = 'nvim',
        [Parameter(Mandatory, Position = 0, ValueFromRemainingArguments)][string[]]$Path
    )

    if (-not (Get-Command wezterm -ErrorAction SilentlyContinue)) {
        Write-Error "wezterm not found on PATH"
        return
    }

    $cwd = (Get-Location).Path

    $wezArgs = switch ($PSCmdlet.ParameterSetName) {
        'SplitRight' {
            $a = @('cli', 'split-pane', '--right', '--cwd', $cwd)
            if ($Percent) { $a += @('--percent', $Percent) }
            $a
        }
        'SplitDown' {
            $a = @('cli', 'split-pane', '--bottom', '--cwd', $cwd)
            if ($Percent) { $a += @('--percent', $Percent) }
            $a
        }
        default {
            @('cli', 'spawn', '--cwd', $cwd)
        }
    }

    $wezArgs += '--'
    $wezArgs += $Editor
    $wezArgs += $Path

    & wezterm @args
}
