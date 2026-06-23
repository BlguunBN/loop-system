@echo off
setlocal
set "SCRIPT_DIR=%~dp0"
if not exist "%SCRIPT_DIR%loop.ps1" (
  echo Error: loop.ps1 not found in %SCRIPT_DIR%
  echo Make sure both loop.cmd and loop.ps1 are in the same directory.
  exit /b 1
)
powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%loop.ps1" %*
exit /b %ERRORLEVEL%
