# Loop engineering stack

This repo already has the bones of a good loop harness. The LangChain article "The Art of Loop Engineering" pushes it one step further: treat the agent as only one loop inside a larger control plane.

## The four loops

1. **Agent loop** — the model plans, edits, and calls tools.
2. **Verification loop** — the harness checks whether the last pass was actually good enough.
3. **Event loop** — schedules, triggers, and webhooks keep work moving without a human re-prompting it.
4. **Hill-climbing loop** — traces and failures feed back into the harness so the next run is better than the last.

## How this repo maps to that model

- `loop tick` is the agent loop entrypoint.
- `loop health` is the lightweight verification gate.
- `loop verify` adds a stronger post-tick review pass for git state and harness sanity.
- `loop interval` and the `focus/start/resume` commands are the control-plane pieces that make the system event-friendly.
- `loop prune` keeps the registry from turning into a junk drawer.

## Recommended operating pattern

1. Bootstrap with `loop init`.
2. Run a tick.
3. Verify the result.
4. Only then run the next tick.
5. If the same failure repeats, change the harness instead of just retrying forever.

## What to optimize over time

- prompt wording
- tool set size
- verification strictness
- tick cadence
- stale-project cleanup

That gives you a simple loop stack that can survive long projects without turning into mush.
