#!/usr/bin/env bash
# Start workd if not already running.

set -euo pipefail

WORKD_BIN=$(tmux show-environment -g WORKD_BIN 2>/dev/null | cut -d= -f2-)

if [[ -z "$WORKD_BIN" ]]; then
    exit 0
fi

# Test scripts set isolated XDG dirs; never let a leaked env reach workd.
case "${XDG_STATE_HOME:-}" in
    /tmp/work-test-* | /tmp/tmp.*/state)
        unset XDG_CONFIG_HOME XDG_STATE_HOME
        ;;
esac

# XDG runtime dir for PID file
RUNTIME_DIR="${XDG_RUNTIME_DIR:-/tmp/work-$(id -u)}/work"
PID_FILE="$RUNTIME_DIR/workd.pid"

if [[ -f "$PID_FILE" ]]; then
    PID=$(cat "$PID_FILE" 2>/dev/null || echo "")
    if [[ -n "$PID" ]] && kill -0 "$PID" 2>/dev/null; then
        exit 0
    fi
    rm -f "$PID_FILE"
fi

mkdir -p "$RUNTIME_DIR"

# Start daemon in background, detached from tmux
read -r -a WORKD_CMD <<<"$WORKD_BIN"
nohup "${WORKD_CMD[@]}" >"$RUNTIME_DIR/workd.log" 2>&1 &
disown
