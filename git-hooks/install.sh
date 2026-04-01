#!/usr/bin/env bash
# Install commit-msg hook globally or into a specific repo.
#
# Usage:
#   ./install.sh              # install globally (git config --global core.hooksPath)
#   ./install.sh /path/to/repo  # install into a single repo
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
HOOK_SRC="$SCRIPT_DIR/commit-msg"

if [[ ! -f "$HOOK_SRC" ]]; then
  echo "error: commit-msg hook not found at $HOOK_SRC" >&2
  exit 1
fi

install_to_dir() {
  local hooks_dir="$1"
  mkdir -p "$hooks_dir"
  cp "$HOOK_SRC" "$hooks_dir/commit-msg"
  chmod +x "$hooks_dir/commit-msg"
  echo "installed commit-msg hook to $hooks_dir"
}

if [[ $# -eq 0 ]]; then
  # Global install
  GLOBAL_HOOKS="$HOME/.git-hooks"
  install_to_dir "$GLOBAL_HOOKS"
  git config --global core.hooksPath "$GLOBAL_HOOKS"
  echo "set global core.hooksPath to $GLOBAL_HOOKS"
else
  # Per-repo install
  REPO="$1"
  if [[ ! -d "$REPO/.git" ]]; then
    echo "error: $REPO is not a git repository" >&2
    exit 1
  fi
  install_to_dir "$REPO/.git/hooks"
fi
