#!/usr/bin/env bash
# Prepend work agent counts to status-right (idempotent).
# Called from ~/.tmux.conf after TPM/theme plugins load.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STATUS_SH="$SCRIPT_DIR/status.sh"
RESTORE_SH="$SCRIPT_DIR/restore-window-format.sh"
MARKER="tmux-tmuxr/scripts/status.sh"

sr="$(tmux show -gv status-right 2>/dev/null || true)"
case "$sr" in
  *"$MARKER"*) ;;
  *)
    tmux set -g status-right "#(bash '$STATUS_SH') $sr"
    ;;
esac

bash "$RESTORE_SH"

# TPM plugin *.tmux files run during source-file; re-apply after they finish.
if [[ -n "${TMUX:-}" ]]; then
  tmux run-shell "sleep 0.3; bash '$RESTORE_SH'" >/dev/null 2>&1 || true
fi

tmux refresh-client -S 2>/dev/null || true
