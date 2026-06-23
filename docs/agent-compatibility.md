# Agent compatibility

The loop system is designed to be runtime-agnostic.

## Supported runtimes

- Hermes
- Claude Code
- Codex
- OpenCode
- Cursor
- any shell-capable agent

## What matters

An agent only needs to be able to:

- read the prompt block
- run commands from a shell
- keep working until the goal is complete

## Notes by runtime

### Hermes
Works with the existing Hermes loop workflow and prompt style.

### Claude Code
Use the generated prompt block as the working directive and keep running the loop commands from the terminal/tooling.

### Codex
Same workflow: read the handoff, run the commands, continue iterating.

### OpenCode
Same workflow: the loop does not care which runtime you use as long as shell commands are available.

### Cursor
Works as long as the runtime can execute terminal commands and preserve project context.

## Portable rule

Do not hardcode agent-specific assumptions into the project docs.
The prompt should tell the agent what to do, not what brand it is.
