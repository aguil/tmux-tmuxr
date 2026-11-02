#!/usr/bin/env bash
# tmux-resurrect post-restore: clear flags and recreate stripped sidebar panes.
#
# Window 0 is created via new-session and never receives after-new-window, so
# sidebar creation must run after resurrect finishes for all sessions.
#
# resurrect runs this hook synchronously and keeps its "Restoring..." spinner up
# until it returns, so only the flags are handled inline. Repair goes to a
# detached worker: it takes minutes on a large server. See issue #31.

set -euo pipefail

SCRIPTS_DIR="${TMUXR_SCRIPTS_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"

if [[ "${1:-}" == "--repair" ]]; then
  bash "$SCRIPTS_DIR/repair-all-sidebars.sh" 2>/dev/null || true
  sleep 0.5
  bash "$SCRIPTS_DIR/repair-all-sidebars.sh" 2>/dev/null || true
  exit 0
fi

# shellcheck source=coalesce-common.sh
source "$SCRIPTS_DIR/coalesce-common.sh"

tmux set-option -gqu @work-restoring 2>/dev/null || true
tmux set-option -gq @work-restore-finished-at "$(date +%s)"

tmuxr_spawn_detached bash "$SCRIPTS_DIR/on-post-restore.sh" --repair
