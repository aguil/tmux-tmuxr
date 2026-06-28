#!/usr/bin/env bash
# Output a short status string for tmux status-right.
# Usage in tmux.conf: set -g status-right '#(bash /path/to/status.sh)'

WORKCTL_BIN=$(tmux show-environment -g WORKCTL_BIN 2>/dev/null | cut -d= -f2- || echo "workctl")
$WORKCTL_BIN status --format tmux 2>/dev/null || echo ""
