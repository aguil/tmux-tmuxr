#!/usr/bin/env bash
# Create sidebar panes in tracked session windows (when sidebar is visible).

set -euo pipefail

SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=sidebar-common.sh
source "$SCRIPTS_DIR/sidebar-common.sh"

while IFS= read -r session_name; do
  [[ -z "$session_name" ]] && continue
  work_ensure_session_sidebars "$session_name" 2>/dev/null || true
done < <(
  tmux list-sessions -F '#{session_name}' 2>/dev/null || true
)
