# Release checklist

Use this before publishing the repo publicly.

## Code

- [ ] `install.ps1` and `bootstrap.ps1` work from a plain PowerShell shell
- [x] `loop.ps1` prints help correctly
- [x] `loop init` works on a clean disposable project
- [x] `loop readme` writes a useful README
- [x] `loop prompt` prints an agent-agnostic handoff
- [x] `loop health`, `loop list`, `loop status`, `loop prune`, and `loop interval` behave as expected
- [x] Windows-native paths render cleanly
- [x] Shell quoting works with spaces in project paths and goals
- [x] `loop.cmd` launches `loop.ps1` in Command Prompt
- [x] Windows install works without Git Bash or WSL

## Docs

- [x] README explains the project in one screen
- [x] Supported runtimes are listed explicitly
- [x] Installation is obvious
- [x] Public usage does not mention Hermes as the only supported runtime
- [x] Release checklist is complete

## Hygiene

- [ ] No secrets in docs or scripts
- [ ] No disposable test directories left behind
- [ ] Generated files are not committed unless intended
- [ ] License file is present
- [ ] `.gitignore` covers loop state and generated handoff files

## Publishing

- [x] Repository title is neutral and public-friendly
- [x] Description says it works with multiple agent runtimes
- [x] Tags/keywords mention loop, agent, automation, and handoff docs
- [x] First public release is tagged
