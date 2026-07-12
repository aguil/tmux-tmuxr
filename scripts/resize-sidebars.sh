#!/usr/bin/env bash
# Debounced sidebar width restore after client resize.

set -euo pipefail

SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=sidebar-common.sh
source "$SCRIPTS_DIR/sidebar-common.sh"

RUNTIME_DIR="${XDG_RUNTIME_DIR:-/tmp/work-$(id -u)}/work"
DEBOUNCE_PID_FILE="$RUNTIME_DIR/tmuxr-resize-sidebars.pid"
DEBOUNCE_MS=150

if [[ -f "$DEBOUNCE_PID_FILE" ]]; then
  kill "$(cat "$DEBOUNCE_PID_FILE")" 2>/dev/null || true
fi

mkdir -p "$RUNTIME_DIR"

(
  sleep "$(awk "BEGIN { printf \"%.3f\", $DEBOUNCE_MS / 1000 }")"
  work_resize_all_sidebars
) &

echo $! >"$DEBOUNCE_PID_FILE"
