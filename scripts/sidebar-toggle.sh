#!/usr/bin/env bash
# Toggle the workctl sidebar in the current tmux window.
# If a sidebar pane exists, kill it. Otherwise, create one.

set -euo pipefail

WORKCTL_BIN=$(tmux show-environment -g WORKCTL_BIN 2>/dev/null | cut -d= -f2-)
SIDEBAR_WIDTH=$(${WORKCTL_BIN} config get sidebar-width 2>/dev/null || echo "40")
SIDEBAR_POSITION=$(${WORKCTL_BIN} config get sidebar-position 2>/dev/null || echo "right")

# Find sidebar pane by user option @workctl-sidebar
SIDEBAR_PANE=""
while IFS=$'\t' read -r pane_id opt_val; do
    if [[ "$opt_val" == "1" ]]; then
        SIDEBAR_PANE="$pane_id"
        break
    fi
done < <(tmux list-panes -F "#{pane_id}	#{@workctl-sidebar}" 2>/dev/null || true)

if [[ -n "$SIDEBAR_PANE" ]]; then
    tmux kill-pane -t "$SIDEBAR_PANE"
    tmux display-message -d 2000 "workctl: sidebar hidden"
else
    if [[ -z "$WORKCTL_BIN" ]]; then
        tmux display-message -d 4000 "workctl: WORKCTL_BIN not set (reload tmux config)"
        exit 1
    fi

    SPLIT_ARGS="-h -l $SIDEBAR_WIDTH"
    if [[ "$SIDEBAR_POSITION" == "left" ]]; then
        SPLIT_ARGS="$SPLIT_ARGS -b"
    fi

    NEW_PANE=$(tmux split-window $SPLIT_ARGS -P -F "#{pane_id}" "${WORKCTL_BIN} sidebar")
    tmux set-option -p -t "$NEW_PANE" @workctl-sidebar 1
    tmux last-pane
    tmux display-message -d 2000 "workctl: sidebar shown"
fi
