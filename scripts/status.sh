#!/usr/bin/env bash
# Output a short status string for tmux status-right.
# Usage in tmux.conf: set -g status-right '#(bash /path/to/status.sh)'

WORK_BIN=$(tmux show-environment -g WORK_BIN 2>/dev/null | cut -d= -f2- || echo "work")
SESSION=""
if [[ -n "${TMUX:-}" ]]; then
  SESSION=$(tmux display-message -p '#{session_name}' 2>/dev/null || true)
fi

ARGS=(status --format tmux)
if [[ -n "$SESSION" ]]; then
  ARGS+=(--session "$SESSION")
fi

if [[ -n "$WORK_BIN" ]]; then
  read -r -a WORK_CMD <<< "$WORK_BIN"
else
  WORK_CMD=(work)
fi
"${WORK_CMD[@]}" "${ARGS[@]}" 2>/dev/null || true
