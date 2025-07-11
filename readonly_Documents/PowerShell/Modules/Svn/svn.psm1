function Get-FilePath {
    param (
        [Parameter(Mandatory = $true)]
        [string]$str
    )
    if ($str -match '([^\s]+)$') {
        return $Matches[1]
    } else {
        Write-Error "Invalid file name format."
        return $null
    }
}

function ss {
    $svnStatus = svn status @args | rg "^[ACDIMRX\?!~]{0,1}-*\s+(.*)$" | Where-Object { $_.Trim() -ne "" }

    if (-not $svnStatus) {
        Write-Host "No output from svn status."
        return
    }

    $selected = $svnStatus | fzf --multi `
        --multi `
        --preview 'svn diff {-1} | delta' `
        --accept-nth=-1 `
        --style=minimal `
        --preview-window=70% `
        --layout=reverse `
        # --bind 'ctrl-q:reload(svn status @args | rg "^[ACDIMRX\?!~]{0,1}-*\s+(.*)$" | Where-Object { $_.Trim() -ne "" })' `

    if (-not $selected) {
        Write-Host "No lines selected."
        return
    }

    return $selected -split "`n"
}

function ssc {
    $selected = ss @args

    if (-not $selected) {
        Write-Host "No lines selected."
        return
    }

    return svn commit $selected
}


function sscl {
    $selected = ss @args

    if (-not $selected) {
        Write-Host "No lines selected."
        return
    }

    Write-Host "You have selected:"
    $selected | ForEach-Object { Write-Host "  - $_" }
    $clname = Read-Host "Please enter a changelist name for these changes"

    if (-not $clname) {
        Write-Host "No name provided."
        return
    }

    return svn changelist $clname $selected
}

function ssu {
    return svn update @args
}
