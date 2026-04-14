#!/usr/bin/env pwsh

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$env:PYTHONIOENCODING = "utf-8"

$old = $args[1].Replace('\', '/')
$new = $args[4].Replace('\', '/')
$path = $args[0]
git diff --no-index --no-ext-diff $old $new `
  | %{ $_.Replace($old, $path).Replace($new, $path) } `
  | delta --dark --paging=never --width=$env:LAZYGIT_COLUMNS
