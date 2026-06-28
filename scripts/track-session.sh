#!/usr/bin/env bash
# Track the current tmux session and scan for agents.

set -euo pipefail

WORK_BIN=$(tmux show-environment -g WORK_BIN 2>/dev/null | cut -d= -f2- || true)
if [[ -z "$WORK_BIN" ]]; then
  tmux display-message -d 4000 "work: WORK_BIN not set (reload tmux config)"
  exit 1
fi

SESSION=$(tmux display-message -p '#{session_name}')
MSG=$($WORK_BIN track "$SESSION" 2>&1) || {
  tmux display-message -d 4000 "work: $MSG"
  exit 1
}

$WORK_BIN scan --session "$SESSION" --quiet 2>/dev/null || true

SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=sidebar-common.sh
source "$SCRIPTS_DIR/sidebar-common.sh"
work_ensure_session_sidebars "$SESSION" 2>/dev/null || true

tmux display-message -d 3000 "work: $MSG"
