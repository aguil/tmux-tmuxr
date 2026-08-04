#!/usr/bin/env bash
# Coalescing dispatcher for the client-resized hook.
#
# Dragging a terminal window emits client-resized dozens of times per second.
# The dispatcher marks the resize pending and returns at once; one detached
# worker debounces and then resizes every sidebar. Previously the debounce
# subshell inherited the tmux job's stdout, so each event held descriptors on
# the tmux server for the whole debounce plus resize (~450ms) -- a drag opened
# far more concurrent jobs than the server had descriptors for. See
# coalesce-common.sh and issue #15.

set -uo pipefail

SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=coalesce-common.sh
source "$SCRIPTS_DIR/coalesce-common.sh"
# shellcheck source=sidebar-common.sh
source "$SCRIPTS_DIR/sidebar-common.sh"

RUNTIME_DIR="$(tmuxr_runtime_dir)"
PENDING_FILE="$RUNTIME_DIR/tmuxr-resize-sidebars.pending"
LOCK_DIR="$RUNTIME_DIR/tmuxr-resize-sidebars.lock"
DEBOUNCE_SECONDS=0.15

drain_pending() {
  tmuxr_lock_claim "$LOCK_DIR"

  while :; do
    # Clear before resizing: events arriving during the pass re-mark the file,
    # so the final window size always gets a pass of its own.
    rm -f "$PENDING_FILE" 2>/dev/null || true
    sleep "$DEBOUNCE_SECONDS"
    work_resize_all_sidebars

    if [[ -e "$PENDING_FILE" ]]; then
      continue
    fi

    tmuxr_lock_release "$LOCK_DIR"
    if [[ -e "$PENDING_FILE" ]] && tmuxr_lock_acquire "$LOCK_DIR"; then
      continue
    fi
    return 0
  done
}

if [[ "${1:-}" == "--drain" ]]; then
  drain_pending
  exit 0
fi

: >"$PENDING_FILE" 2>/dev/null || exit 0

if tmuxr_lock_acquire "$LOCK_DIR"; then
  tmuxr_spawn_detached bash "$SCRIPTS_DIR/resize-sidebars.sh" --drain
  tmuxr_lock_claim "$LOCK_DIR" "$TMUXR_SPAWNED_PID"
fi

exit 0
