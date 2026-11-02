#!/usr/bin/env bash
# Recreate sidebar panes in tracked sessions (optionally one session only).

set -euo pipefail

SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=sidebar-common.sh
source "$SCRIPTS_DIR/sidebar-common.sh"
# shellcheck source=coalesce-common.sh
source "$SCRIPTS_DIR/coalesce-common.sh"

SESSION_FILTER="${1:-}"

if [[ -n "$SESSION_FILTER" ]]; then
  work_repair_session_sidebars "$SESSION_FILTER" 2>/dev/null || true
  exit 0
fi

repair_all_sessions() {
  local session_name

  work_refresh_sidebar_config_cache 2>/dev/null || true

  while IFS= read -r session_name; do
    [[ -z "$session_name" ]] && continue
    work_session_tracked "$session_name" || continue
    work_repair_session_windows "$session_name" 2>/dev/null || true
  done < <(
    tmux list-sessions -F '#{session_name}' 2>/dev/null || true
  )

  work_resize_all_sidebars 2>/dev/null || true
}

# Plugin load and post-restore can both start a pass, so overlapping callers
# coalesce: a caller that finds a pass running leaves a request and exits, and
# the owner runs again. Dropping the request instead could lose the post-restore
# pass to a load-time pass that ran while @work-restoring hid every window.
SERVER_PID=$(tmux display-message -p '#{pid}' 2>/dev/null || true)
if [[ -z "$SERVER_PID" ]]; then
  exit 0
fi
if ! RUNTIME_DIR="$(tmuxr_runtime_dir)"; then
  repair_all_sessions
  exit 0
fi
PENDING_FILE="$RUNTIME_DIR/tmuxr-repair-$SERVER_PID.pending"
LOCK_DIR="$RUNTIME_DIR/tmuxr-repair-$SERVER_PID.lock"

: >"$PENDING_FILE" 2>/dev/null || true
if ! tmuxr_lock_acquire "$LOCK_DIR"; then
  exit 0
fi

while :; do
  rm -f "$PENDING_FILE" 2>/dev/null || true
  repair_all_sessions

  if [[ -e "$PENDING_FILE" ]]; then
    continue
  fi

  tmuxr_lock_release "$LOCK_DIR"
  if [[ -e "$PENDING_FILE" ]] && tmuxr_lock_acquire "$LOCK_DIR"; then
    continue
  fi
  exit 0
done
