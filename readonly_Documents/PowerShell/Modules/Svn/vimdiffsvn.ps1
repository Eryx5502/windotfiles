$file1 = $args[5]
$file2 = $args[6]

if (-not $file1 -or -not $file2) {
  Write-Error "Both file1 and file2 parameters are required."
  return
}

if ((Test-Path $file1) -and (Test-Path $file2)) {
  nvim -d $file1 $file2
} else {
  Write-Error "One or both files do not exist."
}
