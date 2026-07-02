#!/usr/bin/env bash
# Remove live work sidebar panes from tmux-resurrect save files.

set -euo pipefail

SAVE_FILE="${1:-}"
if [[ -z "$SAVE_FILE" || ! -f "$SAVE_FILE" ]]; then
  exit 0
fi

KEYS_FILE=$(mktemp "${TMPDIR:-/tmp}/work-sidebar-keys.XXXXXX")
TMP_FILE=$(mktemp "${TMPDIR:-/tmp}/work-resurrect.XXXXXX")
cleanup() {
  rm -f "$KEYS_FILE" "$TMP_FILE"
}
trap cleanup EXIT

tmux list-panes -a -F '#{session_name}	#{window_index}	#{pane_index}	#{@work-sidebar}' 2>/dev/null |
  awk -F '\t' '$4 == "1" { print $1 "\t" $2 "\t" $3 }' >"$KEYS_FILE"

if [[ ! -s "$KEYS_FILE" ]]; then
  exit 0
fi

awk -F '\t' '
  NR == FNR {
    sidebar[$1 "\t" $2 "\t" $3] = 1
    next
  }
  $1 == "pane" && (($2 "\t" $3 "\t" $6) in sidebar) {
    next
  }
  { print }
' "$KEYS_FILE" "$SAVE_FILE" >"$TMP_FILE"

mv "$TMP_FILE" "$SAVE_FILE"
