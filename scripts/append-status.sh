#!/usr/bin/env bash
# Prepend work agent counts to status-right (idempotent).
# Called from ~/.tmux.conf after TPM/theme plugins load.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STATUS_SH="$SCRIPT_DIR/status.sh"
MARKER="tmux-tmuxr/scripts/status.sh"

sr="$(tmux show -gv status-right 2>/dev/null || true)"
case "$sr" in
  *"$MARKER"*) exit 0 ;;
esac

tmux set -g status-right "#(bash '$STATUS_SH') $sr"
