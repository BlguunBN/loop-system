# Installation

Loop System is intentionally boring to install:

- no package manager
- no build step
- no global daemon

## Fastest install

Use the one-line bootstrap installer:

```bash
curl -fsSL https://raw.githubusercontent.com/BlguunBN/loop-system/main/bootstrap.sh | bash -s --
```

To install into a custom directory:

```bash
curl -fsSL https://raw.githubusercontent.com/BlguunBN/loop-system/main/bootstrap.sh | bash -s -- ~/.local/bin
```

If you want a specific version, pass `--ref`:

```bash
curl -fsSL https://raw.githubusercontent.com/BlguunBN/loop-system/main/bootstrap.sh | bash -s -- --ref v0.1.0
```

## Local clone install

If you already cloned the repository:

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

If the install directory is not already on your `PATH`, add it with your shell profile:

```bash
export PATH="$HOME/bin:$PATH"
```

Or, if you used a custom directory:

```bash
export PATH="$HOME/.local/bin:$PATH"
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

On Windows, run the installer from Git Bash or another Bash-compatible shell.

## Troubleshooting

- **`loop: command not found`** — your install directory is not on `PATH` yet.
- **`bootstrap: need curl or wget`** — install one of those tools first.
- **`bootstrap: need tar`** — install tar or use a Bash environment that includes it.
- **`Missing required script`** — run `bash install.sh` from the repository root.
- **Permission errors** — the target directory may need write access; try a directory under your home folder.

## What gets installed

The installer copies these runtime-neutral entry points:

- `loop`
- `loop.sh`
- `loop-agent-setup.sh`
- `loop-universal-install.sh`
- `loop-readme-install.sh`
- `loop-control.sh`
