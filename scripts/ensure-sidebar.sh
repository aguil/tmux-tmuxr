#!/usr/bin/env bash
# Create a sidebar pane in the specified window if one doesn't already exist.
# Called by after-new-window hook and ensure-all-sidebars.sh.
#
# Usage: ensure-sidebar.sh <window-target>

set -euo pipefail

WINDOW_TARGET="${1:-}"
if [[ -z "$WINDOW_TARGET" ]]; then
    exit 0
fi

WORKCTL_BIN=$(tmux show-environment -g WORKCTL_BIN 2>/dev/null | cut -d= -f2-)
if [[ -z "$WORKCTL_BIN" ]]; then
    exit 0
fi

# Check if sidebar is disabled for this session
SESSION_NAME=$(tmux display-message -t "$WINDOW_TARGET" -p "#{session_name}" 2>/dev/null || echo "")
SIDEBAR_DISABLED=$(tmux show-option -t "$SESSION_NAME" -qv @workctl-sidebar-disabled 2>/dev/null || echo "")
if [[ "$SIDEBAR_DISABLED" == "1" ]]; then
    exit 0
fi

# Check if a sidebar pane already exists in this window
HAS_SIDEBAR=""
while IFS=$'\t' read -r pane_id opt_val; do
    if [[ "$opt_val" == "1" ]]; then
        HAS_SIDEBAR="1"
        break
    fi
done < <(tmux list-panes -t "$WINDOW_TARGET" -F "#{pane_id}	#{@workctl-sidebar}" 2>/dev/null || true)

if [[ -n "$HAS_SIDEBAR" ]]; then
    exit 0
fi

SIDEBAR_WIDTH=$($WORKCTL_BIN config get sidebar-width 2>/dev/null || echo "40")
SIDEBAR_POSITION=$($WORKCTL_BIN config get sidebar-position 2>/dev/null || echo "right")

SPLIT_ARGS="-h -l $SIDEBAR_WIDTH -t $WINDOW_TARGET"
if [[ "$SIDEBAR_POSITION" == "left" ]]; then
    SPLIT_ARGS="$SPLIT_ARGS -b"
fi

NEW_PANE=$(tmux split-window $SPLIT_ARGS -P -F "#{pane_id}" "${WORKCTL_BIN} sidebar")
tmux set-option -p -t "$NEW_PANE" @workctl-sidebar 1
tmux last-pane
