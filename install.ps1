[CmdletBinding()]
param(
  [string]$TargetDir = "$HOME\bin"
)

$ErrorActionPreference = 'Stop'

if ($TargetDir.StartsWith('~\')) {
  $TargetDir = Join-Path $HOME $TargetDir.Substring(2)
}

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$sourceDir = Join-Path $root 'scripts'
$files = @(
  'loop.ps1',
  'loop.cmd',
  'loop.sh',
  'loop-agent-setup.sh',
  'loop-universal-install.sh',
  'loop-readme-install.sh',
  'loop-control.sh'
)

New-Item -ItemType Directory -Force -Path $TargetDir | Out-Null

foreach ($file in $files) {
  $source = Join-Path $sourceDir $file
  $destination = Join-Path $TargetDir $file
  if (-not (Test-Path $source)) {
    throw "Missing source file: $source"
  }
  Copy-Item -Force $source $destination
}

$pathParts = $env:Path -split ';' | Where-Object { $_ }
if ($pathParts -contains $TargetDir) {
  $pathNote = 'This directory is already on your PATH.'
} else {
  $pathNote = "Add $TargetDir to your PATH, or start a new PowerShell window after updating it."
}

Write-Host "Installed loop scripts to: $TargetDir"
Write-Host ''
Write-Host $pathNote
Write-Host ''
Write-Host 'Try:'
Write-Host '  loop --help'
Write-Host '  loop init C:\path\to\project "Build the feature"'