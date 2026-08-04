#!/usr/bin/env bash
# Coalescing dispatcher for the pane-title-changed hook.
#
# The hook fires on every pane title write, and agents rewrite their title
# continuously. Running `work` (a Node CLI, ~200ms per invocation) inline meant
# one concurrent tmux job per title change; see coalesce-common.sh for why that
# breaks the tmux server. Here the hook only records the pane and returns; one
# detached worker drains the queue, so at most one `work` process runs at a time
# and repeated changes to the same pane collapse into a single update.

set -uo pipefail

SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=coalesce-common.sh
source "$SCRIPTS_DIR/coalesce-common.sh"

RUNTIME_DIR="$(tmuxr_runtime_dir)" || exit 0
QUEUE_DIR="$RUNTIME_DIR/tmuxr-title-queue"
LOCK_DIR="$RUNTIME_DIR/tmuxr-title-worker.lock"

# Queue entries are named after the pane. Everything else in the directory is
# left alone, so a directory that turned out not to be ours cannot be emptied
# by this script.
is_queue_entry() { [[ "$1" =~ ^%[0-9]+$ ]]; }

queue_has_entries() {
  local pane_file
  for pane_file in "$QUEUE_DIR"/*; do
    [[ -e "$pane_file" ]] || continue
    is_queue_entry "$(basename "$pane_file")" && return 0
  done
  return 1
}

drain_queue() {
  local work_bin pane_file pane_id
  local -a work_cmd

  tmuxr_lock_claim "$LOCK_DIR"

  work_bin=$(tmux show-environment -g WORK_BIN 2>/dev/null | cut -d= -f2- || true)
  if [[ -z "$work_bin" ]]; then
    for pane_file in "$QUEUE_DIR"/*; do
      pane_id="$(basename "$pane_file")"
      is_queue_entry "$pane_id" || continue
      rm -f "$pane_file" 2>/dev/null || true
    done
    tmuxr_lock_release "$LOCK_DIR"
    return 0
  fi
  read -r -a work_cmd <<<"$work_bin"

  local drained
  while :; do
    drained=0
    for pane_file in "$QUEUE_DIR"/*; do
      [[ -e "$pane_file" ]] || continue
      pane_id="$(basename "$pane_file")"
      is_queue_entry "$pane_id" || continue
      rm -f "$pane_file" 2>/dev/null || true
      drained=1
      "${work_cmd[@]}" agent title-changed "$pane_id" --quiet >/dev/null 2>&1 || true
    done
    if (( drained )); then
      continue
    fi

    tmuxr_lock_release "$LOCK_DIR"
    # An event enqueued between the last scan and the release would otherwise
    # sit in the queue until the next title change; pick it up now.
    if queue_has_entries && tmuxr_lock_acquire "$LOCK_DIR"; then
      continue
    fi
    return 0
  done
}

if [[ "${1:-}" == "--drain" ]]; then
  drain_queue
  exit 0
fi

PANE_ID="${1:-}"
# Pane ids are "%<n>"; anything else would be a path component we should not
# create under the queue directory.
[[ "$PANE_ID" =~ ^%[0-9]+$ ]] || exit 0

tmuxr_ensure_state_dir "$QUEUE_DIR" >/dev/null || exit 0
: >"$QUEUE_DIR/$PANE_ID" 2>/dev/null || exit 0

if tmuxr_lock_acquire "$LOCK_DIR"; then
  tmuxr_spawn_detached bash "$SCRIPTS_DIR/on-pane-title-changed.sh" --drain
  tmuxr_lock_claim "$LOCK_DIR" "$TMUXR_SPAWNED_PID"
fi

exit 0
