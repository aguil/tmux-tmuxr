#!/usr/bin/env bash
# Toggle the workctl sidebar for the entire tracked session.

set -euo pipefail

SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=sidebar-common.sh
source "$SCRIPTS_DIR/sidebar-common.sh"

SESSION=$(tmux display-message -p '#{session_name}')
WORKCTL_BIN=$(tmux show-environment -g WORKCTL_BIN 2>/dev/null | cut -d= -f2- || true)

if [[ -z "$WORKCTL_BIN" ]]; then
  tmux display-message -d 4000 "workctl: WORKCTL_BIN not set (reload tmux config)"
  exit 1
fi

if ! workctl_session_tracked "$SESSION"; then
  tmux display-message -d 3000 "workctl: session is not tracked (prefix + S)"
  exit 1
fi

if workctl_sidebar_visible "$SESSION"; then
  workctl_set_sidebar_visible "$SESSION" 0
  workctl_kill_session_sidebars "$SESSION"
  tmux display-message -d 2000 "workctl: sidebar hidden"
else
  workctl_set_sidebar_visible "$SESSION" 1
  workctl_ensure_session_sidebars "$SESSION"
  tmux display-message -d 2000 "workctl: sidebar shown"
fi
