#!/usr/bin/env bash
# Create a sidebar pane in the specified window if one doesn't already exist.
#
# Usage: ensure-sidebar.sh <window-target>

set -euo pipefail

SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=sidebar-common.sh
source "$SCRIPTS_DIR/sidebar-common.sh"

WINDOW_TARGET="${1:-}"
if [[ -z "$WINDOW_TARGET" ]]; then
  exit 0
fi

WORKCTL_BIN=$(tmux show-environment -g WORKCTL_BIN 2>/dev/null | cut -d= -f2-)
if [[ -z "$WORKCTL_BIN" ]]; then
  exit 0
fi

SESSION_NAME=$(tmux display-message -t "$WINDOW_TARGET" -p "#{session_name}" 2>/dev/null || echo "")
if [[ -z "$SESSION_NAME" ]] || ! workctl_session_tracked "$SESSION_NAME"; then
  exit 0
fi

if ! workctl_sidebar_visible "$SESSION_NAME"; then
  exit 0
fi

LIVE_SIDEBARS=()
while IFS=$'\t' read -r pane_id opt_val dead; do
  if [[ "$opt_val" == "1" && "$dead" != "1" ]]; then
    LIVE_SIDEBARS+=("$pane_id")
  elif [[ "$opt_val" == "1" && "$dead" == "1" ]]; then
    tmux kill-pane -t "$pane_id" 2>/dev/null || true
  fi
done < <(
  tmux list-panes -t "$WINDOW_TARGET" -F "#{pane_id}	#{@workctl-sidebar}	#{pane_dead}" 2>/dev/null || true
)

if [[ "${#LIVE_SIDEBARS[@]}" -gt 1 ]]; then
  for ((i = 1; i < ${#LIVE_SIDEBARS[@]}; i++)); do
    tmux kill-pane -t "${LIVE_SIDEBARS[$i]}" 2>/dev/null || true
  done
fi

if [[ "${#LIVE_SIDEBARS[@]}" -ge 1 ]]; then
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

MAIN_PANE=""
while IFS=$'\t' read -r pane_id marked; do
  if [[ "$marked" != "1" ]]; then
    MAIN_PANE="$pane_id"
    break
  fi
done < <(
  tmux list-panes -t "$WINDOW_TARGET" -F "#{pane_id}	#{@workctl-sidebar}" 2>/dev/null || true
)
if [[ -n "$MAIN_PANE" ]]; then
  tmux select-pane -t "$MAIN_PANE"
fi
