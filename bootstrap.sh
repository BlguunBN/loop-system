#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  curl -fsSL https://raw.githubusercontent.com/BlguunBN/loop-system/main/bootstrap.sh | bash -s -- [target_bin_dir]

Options:
  --repo OWNER/REPO   GitHub repository to install from (default: BlguunBN/loop-system)
  --ref REF           Branch, tag, or commit to install (default: main)
  --help              Show this help text

Examples:
  curl -fsSL https://raw.githubusercontent.com/BlguunBN/loop-system/main/bootstrap.sh | bash -s --
  curl -fsSL https://raw.githubusercontent.com/BlguunBN/loop-system/main/bootstrap.sh | bash -s -- ~/.local/bin
  curl -fsSL https://raw.githubusercontent.com/BlguunBN/loop-system/main/bootstrap.sh | bash -s -- --ref v0.1.0
EOF
}

repo="BlguunBN/loop-system"
ref="main"
target_dir="${HOME}/bin"

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    --repo)
      repo="${2:?missing repo value}"
      shift 2
      ;;
    --ref)
      ref="${2:?missing ref value}"
      shift 2
      ;;
    --install-dir|--target-dir)
      target_dir="${2:?missing target directory}"
      shift 2
      ;;
    --)
      shift
      if [[ $# -gt 0 ]]; then
        target_dir="$1"
        shift
      fi
      ;;
    *)
      target_dir="$1"
      shift
      ;;
  esac
done

if [[ "$target_dir" == '~/'* ]]; then
  target_dir="$HOME/${target_dir#~/}"
fi

if ! command -v curl >/dev/null 2>&1 && ! command -v wget >/dev/null 2>&1; then
  echo "bootstrap: need curl or wget" >&2
  exit 1
fi

if ! command -v tar >/dev/null 2>&1; then
  echo "bootstrap: need tar" >&2
  exit 1
fi

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT
archive="$tmpdir/loop-system.tar.gz"
url="https://codeload.github.com/${repo}/tar.gz/${ref}"

if command -v curl >/dev/null 2>&1; then
  curl -fsSL "$url" -o "$archive"
else
  wget -qO "$archive" "$url"
fi

tar -xzf "$archive" -C "$tmpdir"
repo_dir="$(find "$tmpdir" -mindepth 1 -maxdepth 1 -type d | head -n 1)"

if [[ -z "${repo_dir:-}" || ! -f "$repo_dir/install.sh" ]]; then
  echo "bootstrap: install.sh not found in downloaded archive" >&2
  exit 1
fi

bash "$repo_dir/install.sh" "$target_dir"