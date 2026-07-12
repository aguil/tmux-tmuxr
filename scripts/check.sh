#!/usr/bin/env bash
# Validate shell scripts and plugin layout.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

echo "bash -n …"
for f in tmux-tmuxr.tmux scripts/*.sh; do
  bash -n "$f"
done

if command -v shellcheck >/dev/null 2>&1; then
  echo "shellcheck …"
  shellcheck tmux-tmuxr.tmux scripts/*.sh
else
  echo "shellcheck not installed; skipping"
fi

echo "executable bits …"
EXEC_REQUIRED=(tmux-tmuxr.tmux)
for f in scripts/*.sh; do
  case "$(basename "$f")" in
    hook-common.sh | sidebar-common.sh) continue ;;
  esac
  EXEC_REQUIRED+=("$f")
done
for f in "${EXEC_REQUIRED[@]}"; do
  if [[ ! -x "$f" ]]; then
    echo "not executable: $f" >&2
    exit 1
  fi
done

if [[ ! -f VERSION ]]; then
  echo "missing VERSION file" >&2
  exit 1
fi

echo "check OK"
