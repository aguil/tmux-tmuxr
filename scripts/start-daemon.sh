#!/usr/bin/env bash
# Start workctld if not already running.

set -euo pipefail

WORKCTLD_BIN=$(tmux show-environment -g WORKCTLD_BIN 2>/dev/null | cut -d= -f2-)

if [[ -z "$WORKCTLD_BIN" ]]; then
    exit 0
fi

# Test scripts set isolated XDG dirs; never let a leaked env reach workctld.
case "${XDG_STATE_HOME:-}" in
    /tmp/workctl-test-* | /tmp/tmp.*/state)
        unset XDG_CONFIG_HOME XDG_STATE_HOME
        ;;
esac

# XDG runtime dir for PID file
RUNTIME_DIR="${XDG_RUNTIME_DIR:-/tmp/workctl-$(id -u)}/workctl"
PID_FILE="$RUNTIME_DIR/workctld.pid"

if [[ -f "$PID_FILE" ]]; then
    PID=$(cat "$PID_FILE" 2>/dev/null || echo "")
    if [[ -n "$PID" ]] && kill -0 "$PID" 2>/dev/null; then
        exit 0
    fi
    rm -f "$PID_FILE"
fi

mkdir -p "$RUNTIME_DIR"

# Start daemon in background, detached from tmux
nohup $WORKCTLD_BIN >"$RUNTIME_DIR/workctld.log" 2>&1 &
disown
