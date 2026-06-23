#!/usr/bin/env bash
set -euo pipefail

README_NAME="README.md"
DEFAULT_GOAL='Continue improving this project safely and incrementally.'
LOOP_SCRIPT='loop'
AGENT_NAME='agent'

usage() {
  cat <<'EOF'
Usage:
  hermes-loop-readme-install.sh [--agent NAME] <project_dir> [goal...]
  hermes-loop-readme-install.sh [--agent NAME] --prompt <project_dir> [goal...]
EOF
}

abs_path() {
  local path="$1"
  if command -v cygpath >/dev/null 2>&1; then
    cygpath -m "$path"
  elif [[ -d "$path" ]]; then
    (cd "$path" && pwd)
  else
    echo "$path"
  fi
}

render_readme() {
  local project_dir="$1"
  local goal="$2"
  local agent_name="$3"
  cat <<EOF
# Loop Agent README

Project: $project_dir
Goal: $goal
Runtime: $agent_name

## Start here

1. Health check:

    loop health "$project_dir"

2. Focus the project:

    loop focus "$project_dir" "$goal"

3. Run one loop tick:

    loop tick "$project_dir" "$goal"

4. Inspect the fleet:

    loop list

## Agent prompt

You are the autonomous loop agent for this project.

Compatible runtimes: Hermes, Claude Code, Codex, OpenCode, Cursor, or any agent that can run shell commands.

Project root: $project_dir
Goal: $goal

Rules:
- Use the loop control workflow, not chat-only planning.
- First run health.
- If the project is ready, focus or resume it.
- Then run one safe tick.
- Keep iterating on the next safe step.
- Keep replies short and status-oriented.
- If blocked, report the exact blocker and missing prerequisite.
- Use list/status/focus/tick/interval/prune to manage the loop.

Suggested command sequence:
1. $LOOP_SCRIPT health "$project_dir"
2. $LOOP_SCRIPT focus "$project_dir" "$goal"
3. $LOOP_SCRIPT tick "$project_dir" "$goal"
4. $LOOP_SCRIPT list

## Useful controls

- $LOOP_SCRIPT status "$project_dir"
- $LOOP_SCRIPT interval "$project_dir" 30
- $LOOP_SCRIPT prune 30
EOF
}

if [[ $# -lt 1 ]]; then
  usage
  exit 1
fi

while [[ $# -gt 0 ]]; do
  case "$1" in
    --agent|--runtime)
      AGENT_NAME="${2:-agent}"
      shift 2
      ;;
    --agent=*|--runtime=*)
      AGENT_NAME="${1#*=}"
      shift
      ;;
    --)
      shift
      break
      ;;
    *)
      break
      ;;
  esac
done

mode="install"
if [[ "${1:-}" == "--prompt" ]]; then
  mode="prompt"
  shift
fi

project_dir="${1:-}"
if [[ -z "$project_dir" ]]; then
  usage
  exit 1
fi
shift || true
goal="${*:-$DEFAULT_GOAL}"
project_dir="$(abs_path "$project_dir")"

if [[ "$mode" == "prompt" ]]; then
  render_readme "$project_dir" "$goal" "$AGENT_NAME"
  exit 0
fi

mkdir -p "$project_dir"
render_readme "$project_dir" "$goal" "$AGENT_NAME" > "$project_dir/$README_NAME"
printf 'README: %s\n' "$project_dir/$README_NAME"
