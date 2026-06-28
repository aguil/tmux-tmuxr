#!/usr/bin/env bash
# Track the current tmux session and scan for agents.

set -euo pipefail

WORKCTL_BIN=$(tmux show-environment -g WORKCTL_BIN 2>/dev/null | cut -d= -f2- || true)
if [[ -z "$WORKCTL_BIN" ]]; then
  tmux display-message -d 4000 "workctl: WORKCTL_BIN not set (reload tmux config)"
  exit 1
fi

SESSION=$(tmux display-message -p '#{session_name}')
MSG=$($WORKCTL_BIN track "$SESSION" 2>&1) || {
  tmux display-message -d 4000 "workctl: $MSG"
  exit 1
}

$WORKCTL_BIN scan --session "$SESSION" --quiet 2>/dev/null || true

SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=sidebar-common.sh
source "$SCRIPTS_DIR/sidebar-common.sh"
workctl_ensure_session_sidebars "$SESSION" 2>/dev/null || true

tmux display-message -d 3000 "workctl: $MSG"
