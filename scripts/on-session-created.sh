#!/usr/bin/env bash
# Opt-in auto-track: when auto-track is enabled, track and scan new sessions.
# Hook is always installed; behavior is controlled by workctl config at runtime.

set -euo pipefail

WORKCTL_BIN=$(tmux show-environment -g WORKCTL_BIN 2>/dev/null | cut -d= -f2- || true)
if [[ -z "$WORKCTL_BIN" ]]; then
  exit 0
fi

SESSION="${1:-}"
if [[ -z "$SESSION" ]]; then
  exit 0
fi

AUTO_TRACK=$($WORKCTL_BIN config get auto-track 2>/dev/null || echo "false")
if [[ "$AUTO_TRACK" != "true" ]]; then
  exit 0
fi

$WORKCTL_BIN track "$SESSION" --quiet 2>/dev/null || true
$WORKCTL_BIN scan --session "$SESSION" --quiet 2>/dev/null || true

SCRIPTS_DIR="${TMUXR_SCRIPTS_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"
# shellcheck source=sidebar-common.sh
source "$SCRIPTS_DIR/sidebar-common.sh"
workctl_ensure_session_sidebars "$SESSION" 2>/dev/null || true
