[CmdletBinding()]
param(
  [Parameter(ValueFromRemainingArguments = $true)]
  [string[]]$Args
)

$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$launcher = Join-Path $scriptDir 'loop.sh'

$bashCommand = Get-Command bash -ErrorAction SilentlyContinue
if ($bashCommand) {
  $bashPath = if ($bashCommand.Path) { $bashCommand.Path } else { $bashCommand.Source }
  & $bashPath $launcher @Args
  exit $LASTEXITCODE
}

$gitBashCandidates = @(
  "$env:ProgramFiles\Git\bin\bash.exe",
  "$env:ProgramFiles\Git\usr\bin\bash.exe",
  "$env:ProgramFiles(x86)\Git\bin\bash.exe",
  "$env:ProgramFiles(x86)\Git\usr\bin\bash.exe"
) | Where-Object { $_ -and (Test-Path $_) }

foreach ($candidate in $gitBashCandidates) {
  & $candidate $launcher @Args
  exit $LASTEXITCODE
}

throw @'
Loop System on Windows needs a Bash-compatible shell.
Install Git for Windows, or open the loop command from an environment that already has bash in PATH.
'@