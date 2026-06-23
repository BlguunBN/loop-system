# Installation

Loop System is intentionally boring to install:

- no package manager
- no build step
- no global daemon

## Fastest install

**macOS/Linux/Bash:**

```bash
curl -fsSL https://raw.githubusercontent.com/BlguunBN/loop-system/main/bootstrap.sh | bash -s --
```

**Windows / PowerShell:**

```powershell
irm https://raw.githubusercontent.com/BlguunBN/loop-system/main/bootstrap.ps1 | iex
```

That installs the Windows launcher wrappers plus the shell scripts they call.

If you want a specific install directory on Windows, run the bootstrap script locally:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\bootstrap.ps1 -TargetDir "$HOME\bin"
```

## Local clone install

If you already cloned the repository:

**Bash:**

```bash
git clone https://github.com/BlguunBN/loop-system.git
cd loop-system
bash install.sh
```

**PowerShell:**

```powershell
git clone https://github.com/BlguunBN/loop-system.git
Set-Location loop-system
powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1
```

By default, the installers copy the launchers into `~/bin`.

If you want a different destination on Bash:

```bash
bash install.sh ~/.local/bin
```

If you want a different destination on PowerShell:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1 -TargetDir "$HOME\bin"
```

## Make sure it is on your PATH

If the install directory is not already on your `PATH`, add it with your shell profile:

```bash
export PATH="$HOME/bin:$PATH"
```

Or, if you used a custom directory:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

On Windows PowerShell:

```powershell
$env:Path = "$HOME\bin;$env:Path"
```

Then reload your shell or open a new terminal and verify:

```bash
loop --help
```

## First run

Try the loop on a disposable project directory:

```bash
loop init /path/to/project "Build the feature"
```

## Windows note

Windows gets a native installer and native launcher wrappers (`loop.cmd` and `loop.ps1`). The loop runtime itself still calls into Bash, so install Git for Windows or another Bash-compatible shell if you want to run the shell-backed loop commands on Windows.

## Troubleshooting

- **`loop: command not found`** — your install directory is not on `PATH` yet.
- **`bootstrap: need curl or wget`** — install one of those tools first.
- **`bootstrap: need tar`** — install tar or use a Bash environment that includes it.
- **`Missing required script`** — run `bash install.sh` from the repository root.
- **PowerShell says Bash is missing** — install Git for Windows or another Bash-compatible shell so `loop.ps1` can invoke `loop.sh`.
- **Permission errors** — the target directory may need write access; try a directory under your home folder.

## What gets installed

The installers copy these runtime-neutral entry points:

- `loop`
- `loop.ps1`
- `loop.cmd`
- `loop.sh`
- `loop-agent-setup.sh`
- `loop-universal-install.sh`
- `loop-readme-install.sh`
- `loop-control.sh`
