#!/usr/bin/env bash
# after-new-window hook: scan agents, then optional repo picker.

set -euo pipefail

SESSION="${1:-}"
WINDOW="${2:-}"
PANE="${3:-}"
if [[ -z "$SESSION" ]]; then
  exit 0
fi

SCRIPTS_DIR="${TMUXR_SCRIPTS_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"
WORKCTL_BIN=$(tmux show-environment -g WORKCTL_BIN 2>/dev/null | cut -d= -f2- || true)
if [[ -n "$WORKCTL_BIN" ]]; then
  ($WORKCTL_BIN scan --session "$SESSION" --quiet 2>/dev/null || true) &
fi

bash "$SCRIPTS_DIR/on-new-window.sh" "$SESSION" "$WINDOW" "$PANE"

if [[ -n "$WINDOW" ]]; then
  bash "$SCRIPTS_DIR/ensure-sidebar.sh" "$WINDOW" 2>/dev/null || true
fi
