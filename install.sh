#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  ./install.sh [target_bin_dir]

Installs the loop launcher scripts into the target directory.
Default target: ~/bin

Examples:
  ./install.sh
  ./install.sh ~/.local/bin
EOF
}

if [[ ${1:-} == '-h' || ${1:-} == '--help' ]]; then
  usage
  exit 0
fi

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
target_dir="${1:-$HOME/bin}"

if [[ "$target_dir" == ~/* ]]; then
  target_dir="$HOME/${target_dir#~/}"
fi

mkdir -p "$target_dir"

files=(
  "loop"
  "loop.ps1"
  "loop.cmd"
  "loop.sh"
  "loop-agent-setup.sh"
  "loop-universal-install.sh"
  "loop-readme-install.sh"
  "loop-control.sh"
)

for file in "${files[@]}"; do
  src="$script_dir/scripts/$file"
  dst="$target_dir/$file"
  if [[ ! -f "$src" ]]; then
    echo "Missing source file: $src" >&2
    exit 1
  fi
  cp "$src" "$dst"
  chmod +x "$dst"
done

if [[ ":$PATH:" == *":$target_dir:"* ]]; then
  path_note="This directory is already on your PATH."
else
  path_note="Add $target_dir to your PATH, or start a new shell after updating it."
fi

cat <<EOF
Installed loop scripts to: $target_dir

$path_note

Try:
  loop --help
  loop init /path/to/project "Build the feature"
EOF