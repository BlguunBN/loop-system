# Loop System

A small, agent-agnostic loop harness for continuous project work.

## Install

No package manager. No build step. Just Bash.

```bash
git clone https://github.com/BlguunBN/loop-system.git
cd loop-system
bash install.sh
```

That installs the loop commands into `~/bin` by default.
If you prefer a different destination, use:

```bash
bash install.sh ~/.local/bin
```

After install, make sure the target bin directory is on your `PATH`, then run:

```bash
loop --help
```

See [`INSTALL.md`](INSTALL.md) for the full install guide and troubleshooting.

## What it is

It gives you a consistent workflow for:

- bootstrapping a project into the loop
- writing a fresh-agent README handoff
- generating a runtime-agnostic prompt
- tracking project state across ticks
- keeping one project moving for hours without re-explaining the goal every turn

## Works with

- Hermes
- Claude Code
- Codex
- OpenCode
- Cursor
- any other agent that can run shell commands or consume a prompt block

## Core idea

The loop itself is not the agent.
It is the control plane around the agent.

The agent can be anything, as long as it can:

1. read the handoff prompt
2. run shell commands
3. keep following the loop until the goal is done

## What the loop gives you

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

Once installed, try the loop on a disposable project:

```bash
loop init /path/to/project "Build the feature"
```

That will:

1. bootstrap the project into the loop
2. write a fresh-agent README handoff
3. print the prompt you paste into your agent runtime

## Public release goals

This repo is meant to be easy to publish and easy to reuse:

- no secret material checked in
- clear handoff docs
- generic prompt language
- stable command names
- works across multiple agent runtimes

## Recommended release checklist

See [`docs/release-checklist.md`](docs/release-checklist.md).

## Compatibility notes

See [`docs/agent-compatibility.md`](docs/agent-compatibility.md).