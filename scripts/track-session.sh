#!/usr/bin/env bash
# Track the current tmux session and scan for agents.

set -euo pipefail

SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=work-bin-common.sh
source "$SCRIPTS_DIR/work-bin-common.sh"

WORK_BIN=$(tmux show-environment -g WORK_BIN 2>/dev/null | cut -d= -f2- || true)
if [[ -z "$WORK_BIN" ]]; then
  WORK_BIN=$(resolve_bin work)
  if [[ -n "$WORK_BIN" ]]; then
    if ! work_meets_min_version "$WORK_BIN"; then
      WORK_VER=$(work_bin_version "$WORK_BIN")
      tmux display-message -d 4000 \
        "tmux-tmuxr: work $WORK_VER < $MIN_WORK_VERSION (npm install -g @aguil/work)"
      exit 1
    fi
    tmux set-environment -g WORK_BIN "$WORK_BIN" 2>/dev/null || true
  else
    tmux display-message -d 4000 "work: WORK_BIN not set (reload tmux config)"
    exit 1
  fi
fi

SESSION=$(tmux display-message -p '#{session_name}')
MSG=$($WORK_BIN track "$SESSION" 2>&1) || {
  tmux display-message -d 4000 "work: $MSG"
  # Message already shown; avoid tmux run-shell surfacing a second failure.
  exit 0
}

$WORK_BIN scan --session "$SESSION" --quiet 2>/dev/null || true

# shellcheck source=sidebar-common.sh
source "$SCRIPTS_DIR/sidebar-common.sh"
work_ensure_session_sidebars "$SESSION" 2>/dev/null || true

tmux display-message -d 3000 "work: $MSG"
