#!/usr/bin/env bash
# Archive tracked workspace when a tmux session closes.

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

$WORK_BIN untrack "$SESSION" --auto --quiet 2>/dev/null || true
