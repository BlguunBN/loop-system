# Scripts folder

This folder contains the public loop entry points.

## Windows native

The Windows path is PowerShell-first and does not require Bash or WSL:

- `loop.ps1` — native CLI and project loop controller
- `loop.cmd` — Command Prompt wrapper that launches `loop.ps1`

## Cross-platform Bash

The Bash scripts remain for macOS / Linux users and for compatibility with the original install path:

- `loop`
- `loop.sh`
- `loop-agent-setup.sh`
- `loop-universal-install.sh`
- `loop-readme-install.sh`
- `loop-control.sh`

The root `install.sh` script installs the Bash entry points.
The root `install.ps1` script installs the Windows-native entry points.
