# Release checklist

Use this before publishing the repo publicly.

## Code

- [ ] `loop` prints help correctly
- [ ] `loop init` works on a clean disposable project
- [ ] `loop readme` writes a useful README
- [ ] `loop prompt` prints an agent-agnostic handoff
- [ ] `loop health`, `loop list`, `loop status`, `loop prune`, and `loop interval` behave as expected
- [ ] Windows paths render cleanly
- [ ] Shell quoting works with spaces in project paths and goals

## Docs

- [ ] README explains the project in one screen
- [ ] Supported runtimes are listed explicitly
- [ ] Installation is obvious
- [ ] Public usage does not mention Hermes as the only supported runtime
- [ ] Release checklist is complete

## Hygiene

- [ ] No secrets in docs or scripts
- [ ] No disposable test directories left behind
- [ ] Generated files are not committed unless intended
- [ ] License file is present
- [ ] `.gitignore` covers loop state and generated handoff files

## Publishing

- [ ] Repository title is neutral and public-friendly
- [ ] Description says it works with multiple agent runtimes
- [ ] Tags/keywords mention loop, agent, automation, and handoff docs
- [ ] First public release is tagged
