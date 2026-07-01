#!/usr/bin/env bash
# Opt-in auto-track: when auto-track is enabled, track and scan new sessions.
# Hook is always installed; behavior is controlled by work config at runtime.

set -euo pipefail

WORK_BIN=$(tmux show-environment -g WORK_BIN 2>/dev/null | cut -d= -f2- || true)
if [[ -z "$WORK_BIN" ]]; then
  exit 0
fi

SCRIPTS_DIR="${TMUXR_SCRIPTS_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"
# shellcheck source=hook-common.sh
source "$SCRIPTS_DIR/hook-common.sh"

SESSION=""
if [[ "${1:-}" =~ ^[0-9]+$ ]]; then
  SESSION=$(hook_session_name_from_id "$1")
else
  SESSION="${1:-}"
fi
if [[ -z "$SESSION" ]]; then
  exit 0
fi

AUTO_TRACK=$($WORK_BIN config get auto-track 2>/dev/null || echo "false")
if [[ "$AUTO_TRACK" != "true" ]]; then
  exit 0
fi

$WORK_BIN track "$SESSION" --quiet 2>/dev/null || true
$WORK_BIN scan --session "$SESSION" --quiet 2>/dev/null || true

# shellcheck source=sidebar-common.sh
source "$SCRIPTS_DIR/sidebar-common.sh"
work_ensure_session_sidebars "$SESSION" 2>/dev/null || true
