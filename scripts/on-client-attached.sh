#!/usr/bin/env bash
# On attach: clear stale flags and repair sidebar panes after restore.

set -euo pipefail

SCRIPTS_DIR="${TMUXR_SCRIPTS_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"
# shellcheck source=hook-common.sh
source "$SCRIPTS_DIR/hook-common.sh"
# shellcheck source=sidebar-common.sh
source "$SCRIPTS_DIR/sidebar-common.sh"

SESSION=""
if [[ "${1:-}" =~ ^[0-9]+$ ]]; then
  SESSION=$(hook_session_name_from_id "$1")
else
  SESSION="${1:-}"
fi
if [[ -z "$SESSION" ]]; then
  exit 0
fi

tmux set-option -t "$SESSION" -u @work-repo-picker 2>/dev/null || true
tmux set-option -t "$SESSION" -u @work-action-picker 2>/dev/null || true

work_repair_session_sidebars "$SESSION"
