#!/usr/bin/env bash
# On attach: clear stale flags and repair sidebar panes after restore.

set -euo pipefail

SESSION="${1:-}"
if [[ -z "$SESSION" ]]; then
  exit 0
fi

SCRIPTS_DIR="${TMUXR_SCRIPTS_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"
# shellcheck source=sidebar-common.sh
source "$SCRIPTS_DIR/sidebar-common.sh"

tmux set-option -t "$SESSION" -u @workctl-repo-picker 2>/dev/null || true
tmux set-option -t "$SESSION" -u @workctl-action-picker 2>/dev/null || true

workctl_repair_session_sidebars "$SESSION"
