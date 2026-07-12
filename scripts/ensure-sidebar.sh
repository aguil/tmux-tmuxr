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

WORK_BIN=$(tmux show-environment -g WORK_BIN 2>/dev/null | cut -d= -f2-)
if [[ -z "$WORK_BIN" ]]; then
  exit 0
fi

SESSION_NAME=$(tmux display-message -t "$WINDOW_TARGET" -p "#{session_name}" 2>/dev/null || echo "")
if [[ -z "$SESSION_NAME" ]] || ! work_session_tracked "$SESSION_NAME"; then
  exit 0
fi

if ! work_sidebar_visible "$SESSION_NAME"; then
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
  tmux list-panes -t "$WINDOW_TARGET" -F "#{pane_id}	#{@work-sidebar}	#{pane_dead}" 2>/dev/null || true
)

if [[ "${#LIVE_SIDEBARS[@]}" -gt 1 ]]; then
  for ((i = 1; i < ${#LIVE_SIDEBARS[@]}; i++)); do
    tmux kill-pane -t "${LIVE_SIDEBARS[$i]}" 2>/dev/null || true
  done
fi

if [[ "${#LIVE_SIDEBARS[@]}" -ge 1 ]]; then
  exit 0
fi

SIDEBAR_WIDTH=$(work_sidebar_config_width)
SIDEBAR_POSITION=$(work_sidebar_config_position)

split_args=(-h -l "$SIDEBAR_WIDTH" -t "$WINDOW_TARGET")
if [[ "$SIDEBAR_POSITION" == "left" ]]; then
  split_args+=(-b)
fi

NEW_PANE=$(tmux split-window "${split_args[@]}" -P -F "#{pane_id}" "${WORK_BIN} sidebar")
tmux set-option -p -t "$NEW_PANE" @work-sidebar 1

MAIN_PANE=""
while IFS=$'\t' read -r pane_id marked; do
  if [[ "$marked" != "1" ]]; then
    MAIN_PANE="$pane_id"
    break
  fi
done < <(
  tmux list-panes -t "$WINDOW_TARGET" -F "#{pane_id}	#{@work-sidebar}" 2>/dev/null || true
)
if [[ -n "$MAIN_PANE" ]]; then
  tmux select-pane -t "$MAIN_PANE"
fi
