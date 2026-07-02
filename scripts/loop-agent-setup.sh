#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONTROL_SCRIPT="$SCRIPT_DIR/loop-control.sh"
AGENT_NAME="agent"

usage() {
  cat <<'EOF'
Usage:
  hermes-loop-agent-setup.sh [--agent NAME] bootstrap <project_dir> [goal...]
  hermes-loop-agent-setup.sh [--agent NAME] setup <project_dir> [goal...]        # alias for bootstrap
  hermes-loop-agent-setup.sh [--agent NAME] resume <project_dir> [goal...]
  hermes-loop-agent-setup.sh [--agent NAME] focus <project_dir> [goal...]
  hermes-loop-agent-setup.sh [--agent NAME] tick <project_dir> [goal...]
  hermes-loop-agent-setup.sh [--agent NAME] health <project_dir>
  hermes-loop-agent-setup.sh [--agent NAME] verify <project_dir>
  hermes-loop-agent-setup.sh [--agent NAME] status <project_dir>
  hermes-loop-agent-setup.sh [--agent NAME] prompt <project_dir> [goal...]
  hermes-loop-agent-setup.sh list
  hermes-loop-agent-setup.sh prune [days]
EOF
}

project_dir_abs() {
  local project_dir="$1"
  if command -v cygpath >/dev/null 2>&1; then
    cygpath -m "$project_dir"
  elif [[ -d "$project_dir" ]]; then
    (cd "$project_dir" && pwd)
  else
    echo "$project_dir"
  fi
}

show_prompt() {
  local project_dir="$1"
  local goal="${2:-Continue improving this project safely and incrementally.}"
  cat <<EOF
You are the autonomous loop agent for this project.

Compatible runtimes: Hermes, Claude Code, Codex, OpenCode, Cursor, or any other agent that can run shell commands.

Project root: $project_dir
Goal: $goal
Runtime: $AGENT_NAME

Rules:
- Use the loop control workflow, not chat-only planning.
- First run health.
- If the project is ready, focus or resume it.
- Then run one safe tick.
- If the tick changed code or docs, run `loop verify` before the next tick.
- Keep iterating on the next safe step.
- Keep replies short and status-oriented.
- If blocked, report the exact blocker and missing prerequisite.
- Use list/status/focus/tick/interval/prune to manage the loop.

Suggested command sequence:
1. loop health "$project_dir"
2. loop focus "$project_dir" "$goal"
3. loop tick "$project_dir" "$goal"
4. loop verify "$project_dir"
5. loop list
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

if [[ $# -lt 1 ]]; then
  usage
  exit 1
fi

action="$1"
shift || true

case "$action" in
  bootstrap|setup|resume|focus|tick|health|status|prompt)
    project_dir="${1:-}"
    if [[ -z "$project_dir" ]]; then
      echo "Missing PROJECT_DIR" >&2
      exit 1
    fi
    shift || true
    goal="${*:-}"
    project_dir="$(project_dir_abs "$project_dir")"
    ;;
  list|prune)
    goal="${*:-}"
    project_dir=""
    ;;
  *)
    usage
    exit 1
    ;;
esac

if [[ ! -x "$CONTROL_SCRIPT" ]]; then
  echo "Missing loop control script: $CONTROL_SCRIPT" >&2
  exit 1
fi

case "$action" in
  bootstrap|setup)
    args=(new "$project_dir")
    [[ -n "$goal" ]] && args+=("$goal")
    exec "$CONTROL_SCRIPT" "${args[@]}"
    ;;
  resume)
    args=(resume "$project_dir")
    [[ -n "$goal" ]] && args+=("$goal")
    exec "$CONTROL_SCRIPT" "${args[@]}"
    ;;
  focus)
    args=(focus "$project_dir")
    [[ -n "$goal" ]] && args+=("$goal")
    exec "$CONTROL_SCRIPT" "${args[@]}"
    ;;
  tick)
    args=(tick "$project_dir")
    [[ -n "$goal" ]] && args+=("$goal")
    exec "$CONTROL_SCRIPT" "${args[@]}"
    ;;
  health)
    exec "$CONTROL_SCRIPT" health "$project_dir"
    ;;
  verify)
    exec "$CONTROL_SCRIPT" verify "$project_dir"
    ;;
  status)
    exec "$CONTROL_SCRIPT" status "$project_dir"
    ;;
  list)
    exec "$CONTROL_SCRIPT" list
    ;;
  prune)
    exec "$CONTROL_SCRIPT" prune ${goal:-30}
    ;;
  prompt)
    show_prompt "$project_dir" "$goal"
    ;;
esac
