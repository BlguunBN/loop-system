[CmdletBinding()]
param(
  [string]$TargetDir = "$HOME\bin",
  [string]$Repo = 'BlguunBN/loop-system',
  [string]$Ref = 'main'
)

$ErrorActionPreference = 'Stop'

if ($TargetDir.StartsWith('~\')) {
  $TargetDir = Join-Path $HOME $TargetDir.Substring(2)
}

switch -regex ($Ref) {
  '^refs/' { $archiveRef = $Ref }
  '^(heads|tags)/' { $archiveRef = "refs/$Ref" }
  default { $archiveRef = "refs/heads/$Ref" }
}

$repoName = ($Repo -split '/')[1]
$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("loop-system-" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $tempRoot | Out-Null

try {
  $archive = Join-Path $tempRoot 'loop-system.zip'
  $downloadUrl = "https://codeload.github.com/$Repo/zip/$archiveRef"

  Invoke-WebRequest -Uri $downloadUrl -OutFile $archive
  Expand-Archive -Path $archive -DestinationPath $tempRoot -Force

  $repoDir = Get-ChildItem -Path $tempRoot -Directory | Where-Object { $_.Name -like "$repoName-*" } | Select-Object -First 1
  if (-not $repoDir) {
    throw 'bootstrap: downloaded archive did not contain the repository root'
  }

  $installScript = Join-Path $repoDir.FullName 'install.ps1'
  if (-not (Test-Path $installScript)) {
    throw 'bootstrap: install.ps1 not found in downloaded archive'
  }

  & $installScript -TargetDir $TargetDir
}
finally {
  Remove-Item -Recurse -Force $tempRoot -ErrorAction SilentlyContinue
}