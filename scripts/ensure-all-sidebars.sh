#!/usr/bin/env bash
# Create sidebar panes in all existing windows of all sessions.
# Called once on plugin load.

set -euo pipefail

SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

while IFS=$'\t' read -r session_name window_index; do
    bash "$SCRIPTS_DIR/ensure-sidebar.sh" "${session_name}:${window_index}" 2>/dev/null || true
done < <(tmux list-windows -a -F "#{session_name}	#{window_index}" 2>/dev/null || true)
