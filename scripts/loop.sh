#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SETUP_SCRIPT="$SCRIPT_DIR/loop-agent-setup.sh"
UNIVERSAL_INSTALL_SCRIPT="$SCRIPT_DIR/loop-universal-install.sh"

usage() {
  cat <<'EOF'
Usage:
  loop <project_dir> [goal...]                     # bootstrap a project into the loop
  loop install <project_dir> [goal...]             # alias for bootstrap
  loop prompt <project_dir> [goal...]              # print the handoff prompt only
  loop {new|start|resume|focus|tick|health|verify|status} <project_dir> [goal...]
  loop list
  loop prune [days]
  loop interval <project_dir> <minutes>
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

require_script() {
  local script="$1"
  if [[ ! -x "$script" ]]; then
    echo "Missing required script: $script" >&2
    exit 1
  fi
}

if [[ $# -lt 1 ]]; then
  usage
  exit 1
fi

cmd="$1"
shift || true

case "$cmd" in
  help|-h|--help)
    usage
    exit 0
    ;;
  install|bootstrap|setup)
    require_script "$UNIVERSAL_INSTALL_SCRIPT"
    if [[ $# -lt 1 ]]; then
      usage
      exit 1
    fi
    project_dir="$(abs_path "$1")"
    shift || true
    goal=("$@")
    exec "$UNIVERSAL_INSTALL_SCRIPT" "$project_dir" "${goal[@]}"
    ;;
  prompt)
    require_script "$SETUP_SCRIPT"
    if [[ $# -lt 1 ]]; then
      usage
      exit 1
    fi
    project_dir="$(abs_path "$1")"
    shift || true
    goal=("$@")
    exec "$SETUP_SCRIPT" prompt "$project_dir" "${goal[@]}"
    ;;
  list|prune)
    require_script "$SETUP_SCRIPT"
    exec "$SETUP_SCRIPT" "$cmd" "$@"
    ;;
  new|start|resume|focus|tick|health|verify|status)
    require_script "$SETUP_SCRIPT"
    if [[ $# -lt 1 ]]; then
      usage
      exit 1
    fi
    project_dir="$(abs_path "$1")"
    shift || true
    goal=("$@")
    exec "$SETUP_SCRIPT" "$cmd" "$project_dir" "${goal[@]}"
    ;;
  interval)
    require_script "$SETUP_SCRIPT"
    if [[ $# -lt 2 ]]; then
      usage
      exit 1
    fi
    project_dir="$(abs_path "$1")"
    minutes="$2"
    exec "$SETUP_SCRIPT" interval "$project_dir" "$minutes"
    ;;
  *)
    # Default: treat first arg as project dir and bootstrap it.
    require_script "$UNIVERSAL_INSTALL_SCRIPT"
    project_dir="$(abs_path "$cmd")"
    goal=("$@")
    exec "$UNIVERSAL_INSTALL_SCRIPT" "$project_dir" "${goal[@]}"
    ;;
esac
