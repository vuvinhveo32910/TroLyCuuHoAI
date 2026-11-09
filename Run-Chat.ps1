# Keep script text ASCII-compatible with Windows PowerShell 5.1.
param([string]$Python = 'D:\Models\medgemma-env\Scripts\python.exe', [switch]$NoPreload)
$ErrorActionPreference = 'Stop'
if (-not (Test-Path -LiteralPath $Python)) { throw 'Chon Python co cac thu vien AI bang tham so -Python.' }
$chatArguments = @('-X','utf8','-B',(Join-Path $PSScriptRoot 'backend\run_chat.py'))
if ($NoPreload) { $chatArguments += '--no-preload' }
& $Python @chatArguments
