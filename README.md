# Loop System

A loop harness for continuous project work across coding agents.

It keeps the project moving without re-explaining the goal every turn.

## Install

### Windows, native PowerShell

No Bash required.

```powershell
irm https://raw.githubusercontent.com/BlguunBN/loop-system/main/bootstrap.ps1 | iex
```

If you already cloned the repo:

```powershell
.\install.ps1
```

That installs:

- `loop.ps1`
- `loop.cmd`

### macOS / Linux

```bash
git clone https://github.com/BlguunBN/loop-system.git
cd loop-system
bash install.sh
```

Then make sure the install directory is on your `PATH` and run:

```bash
loop --help
```

See [`INSTALL.md`](INSTALL.md) for full install steps and troubleshooting.

## What it does

Loop System gives you a repeatable workflow for:

- bootstrapping a project into the loop
- writing a fresh-agent README handoff
- generating an agent-agnostic prompt
- tracking project state across ticks
- keeping one project moving over long sessions

## Works with

Loop System is **agent-agnostic**. It works with any coding agent that can:

1. read the handoff prompt
2. run shell commands
3. keep following the loop until the goal is done

Supported examples:

- Hermes
- Claude Code
- Codex
- OpenCode
- Cursor
- other agents with terminal access

## Core idea

The loop is not the agent.
It is the control plane around the agent.

## Commands

| Command | What it does |
|---|---|
| `loop init <project> [goal...]` | bootstrap the project, write README, print the handoff prompt |
| `loop readme <project> [goal...]` | write only the project README handoff |
| `loop prompt <project> [goal...]` | print only the agent prompt |
| `loop health <project>` | check whether the project looks healthy |
| `loop focus <project> [goal...]` | set the active project |
| `loop tick <project> [goal...]` | run one iteration of the loop |
| `loop list` | list tracked projects |
| `loop interval <project> <minutes>` | set how often summaries should happen |
| `loop prune [days]` | remove stale inactive projects |

## First run

Try it on a disposable project:

```powershell
loop init C:\path\to\project "Build the feature"
```

That will:

1. bootstrap the project into the loop
2. write a README handoff for the agent
3. print the prompt you paste into your coding agent

## Public release goals

This repo is meant to be boring to install and easy to reuse:

- no secrets checked in
- clear handoff docs
- generic prompt language
- stable command names
- Windows-native install path
- releaseable tags for public users

## Releases

Tags that start with `v` are published automatically by GitHub Actions.
That gives strangers a versioned entry point instead of a moving target.

## More docs

- [`INSTALL.md`](INSTALL.md) — install and troubleshooting
- [`docs/agent-compatibility.md`](docs/agent-compatibility.md) — which agents and shells are supported
- [`docs/release-checklist.md`](docs/release-checklist.md) — release hygiene and verification
