#!/usr/bin/env bash
# Toggle the work sidebar for the entire tracked session.

set -euo pipefail

SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=sidebar-common.sh
source "$SCRIPTS_DIR/sidebar-common.sh"

SESSION=$(tmux display-message -p '#{session_name}')
WORK_BIN=$(tmux show-environment -g WORK_BIN 2>/dev/null | cut -d= -f2- || true)

if [[ -z "$WORK_BIN" ]]; then
  tmux display-message -d 4000 "work: WORK_BIN not set (reload tmux config)"
  exit 1
fi

if ! work_session_tracked "$SESSION"; then
  tmux display-message -d 3000 "work: session is not tracked (prefix + S)"
  exit 0
fi

if work_sidebar_visible "$SESSION"; then
  work_set_sidebar_visible "$SESSION" 0
  work_kill_session_sidebars "$SESSION"
  tmux display-message -d 2000 "work: sidebar hidden"
else
  work_set_sidebar_visible "$SESSION" 1
  work_ensure_session_sidebars "$SESSION"
  tmux display-message -d 2000 "work: sidebar shown"
fi
