#!/usr/bin/env bash
set -euo pipefail

SETUP_SCRIPT="/c/Users/bilgu/bin/hermes-loop-agent-setup.sh"
DOC_NAME="LOOP_AGENT_START.md"
DEFAULT_GOAL='Continue improving this project safely and incrementally.'
AGENT_NAME="agent"

usage() {
  cat <<'EOF'
Usage:
  hermes-loop-universal-install.sh [--agent NAME] <project_dir> [goal...]
  hermes-loop-universal-install.sh [--agent NAME] --prompt <project_dir> [goal...]
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

mode="install"
if [[ "$1" == "--prompt" ]]; then
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
project_dir="$(project_dir_abs "$project_dir")"

if [[ ! -x "$SETUP_SCRIPT" ]]; then
  echo "Missing loop setup script: $SETUP_SCRIPT" >&2
  exit 1
fi

if [[ "$mode" == "prompt" ]]; then
  exec "$SETUP_SCRIPT" --agent "$AGENT_NAME" prompt "$project_dir" "$goal"
fi

mkdir -p "$project_dir"
if [[ ! -d "$project_dir/.git" ]]; then
  if command -v git >/dev/null 2>&1; then
    git -C "$project_dir" init -b main >/dev/null 2>&1 || git -C "$project_dir" init >/dev/null 2>&1 || true
  fi
fi

setup_output="$($SETUP_SCRIPT --agent "$AGENT_NAME" bootstrap "$project_dir" "$goal")"
prompt_output="$($SETUP_SCRIPT --agent "$AGENT_NAME" prompt "$project_dir" "$goal")"

{
  cat <<EOF
# Loop Agent Start

Project: $project_dir
Goal: $goal
Runtime: ${AGENT_NAME}

## First step for a fresh agent

1. Read this file.
2. Run:

   \\`loop health "$project_dir"\\`
3. Then run:

   \\`loop focus "$project_dir" "$goal"\\`
4. Then run:

   \\`loop tick "$project_dir" "$goal"\\`

## Prompt for a new agent

EOF
  printf '```text\n%s\n```\n\n' "$prompt_output"
  cat <<EOF
## Loop control shortcuts

- \\`loop list\\`
- \\`loop status "$project_dir"\\`
- \\`loop interval "$project_dir" 30\\`
- \\`loop prune 30\\`
EOF
} > "$project_dir/$DOC_NAME"

printf '%s\n' "$setup_output"
printf 'DOC: %s\n' "$project_dir/$DOC_NAME"
printf '%s\n' "$prompt_output"
