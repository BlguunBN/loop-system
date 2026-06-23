# Installation

Loop System is intentionally boring to install:

- no package manager
- no build step
- no global daemon

## Windows native install

No Bash required.

```powershell
irm https://raw.githubusercontent.com/BlguunBN/loop-system/main/bootstrap.ps1 | iex
```

That downloads the repo archive, expands it, and runs the PowerShell installer.

If you've already cloned the repo locally:

```powershell
.\install.ps1
```

That installs the native Windows launchers into `~/bin` by default.

## macOS / Linux quick install

From the repo root:

```bash
git clone https://github.com/BlguunBN/loop-system.git
cd loop-system
bash install.sh
```

By default, the installer copies the public loop launchers into `~/bin`.

If you want a different destination:

```bash
bash install.sh ~/.local/bin
```

## Make sure it is on your PATH

If the install directory is not already on your `PATH`, add it with your shell profile.

Windows PowerShell:

```powershell
$env:Path = "$HOME\bin;$env:Path"
```

PowerShell profile example:

```powershell
[Environment]::SetEnvironmentVariable('Path', "$HOME\bin;$([Environment]::GetEnvironmentVariable('Path','User'))", 'User')
```

macOS / Linux:

```bash
export PATH="$HOME/bin:$PATH"
```

Then reload your shell or open a new terminal and verify:

```bash
loop --help
```

## First run

Try the loop on a disposable project directory:

```powershell
loop init C:\path\to\project "Build the feature"
```

## Troubleshooting

- **`loop: command not found`** — your install directory is not on `PATH` yet.
- **`Missing source file`** — run the installer from the repository root or use the bootstrap command.
- **Permission errors** — the target directory may need write access; try a directory under your home folder.

## What gets installed

The native Windows path installs:

- `loop.ps1`
- `loop.cmd`

The cross-platform Bash path installs:

- `loop`
- `loop.sh`
- `loop-agent-setup.sh`
- `loop-universal-install.sh`
- `loop-readme-install.sh`
- `loop-control.sh`
