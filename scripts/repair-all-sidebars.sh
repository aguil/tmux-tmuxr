#!/usr/bin/env bash
# Recreate sidebar panes in tracked sessions (optionally one session only).

set -euo pipefail

SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=sidebar-common.sh
source "$SCRIPTS_DIR/sidebar-common.sh"

SESSION_FILTER="${1:-}"

if [[ -n "$SESSION_FILTER" ]]; then
  work_repair_session_sidebars "$SESSION_FILTER" 2>/dev/null || true
  exit 0
fi

while IFS= read -r session_name; do
  [[ -z "$session_name" ]] && continue
  work_repair_session_sidebars "$session_name" 2>/dev/null || true
done < <(
  tmux list-sessions -F '#{session_name}' 2>/dev/null || true
)
