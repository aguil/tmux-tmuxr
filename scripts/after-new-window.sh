#!/usr/bin/env bash
# after-new-window hook: scan agents, then optional repo picker.

set -euo pipefail

WINDOW="${1:-}"
PANE="${2:-}"
SESSION=""
if [[ -n "$WINDOW" ]]; then
  SESSION=$(tmux display-message -p -t "$WINDOW" '#{session_name}' 2>/dev/null || true)
fi
if [[ -z "$SESSION" ]]; then
  exit 0
fi

SCRIPTS_DIR="${TMUXR_SCRIPTS_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"
WORK_BIN=$(tmux show-environment -g WORK_BIN 2>/dev/null | cut -d= -f2- || true)
if [[ -n "$WORK_BIN" ]]; then
  if [[ -n "$PANE" ]]; then
    ($WORK_BIN scan --pane "$PANE" --quiet 2>/dev/null || true) &
  else
    ($WORK_BIN scan --session "$SESSION" --quiet 2>/dev/null || true) &
  fi
fi

bash "$SCRIPTS_DIR/on-new-window.sh" "$SESSION" "$WINDOW" "$PANE" || true

if [[ -n "$WINDOW" ]]; then
  bash "$SCRIPTS_DIR/ensure-sidebar.sh" "$WINDOW" 2>/dev/null || true
fi
