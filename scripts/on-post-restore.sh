#!/usr/bin/env bash
# tmux-resurrect post-restore: clear flags and recreate stripped sidebar panes.
#
# Window 0 is created via new-session and never receives after-new-window, so
# sidebar creation must run after resurrect finishes for all sessions.

set -euo pipefail

SCRIPTS_DIR="${TMUXR_SCRIPTS_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"

if [[ "${1:-}" != "--retry" ]]; then
  tmux set-option -gqu @work-restoring 2>/dev/null || true
  tmux set-option -gq @work-restore-finished-at "$(date +%s)"
fi

bash "$SCRIPTS_DIR/repair-all-sidebars.sh" 2>/dev/null || true

if [[ "${1:-}" != "--retry" && -n "${TMUX:-}" ]]; then
  tmux run-shell "sleep 0.5; bash '$SCRIPTS_DIR/on-post-restore.sh' --retry" >/dev/null 2>&1 || true
fi
