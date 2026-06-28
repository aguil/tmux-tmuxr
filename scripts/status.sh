#!/usr/bin/env bash
# Output a short status string for tmux status-right.
# Usage in tmux.conf: set -g status-right '#(bash /path/to/status.sh)'

WORK_BIN=$(tmux show-environment -g WORK_BIN 2>/dev/null | cut -d= -f2- || echo "work")
$WORK_BIN status --format tmux 2>/dev/null || echo ""
