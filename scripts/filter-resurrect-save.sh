#!/usr/bin/env bash
# Post-process tmux-resurrect save files: repair pane lines whose empty pane
# title shifted every later field, then remove live work sidebar panes.

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
  awk -F '\t' '$4 == "1" { print $1 "\t" $2 "\t" $3 }' >"$KEYS_FILE" || true

# resurrect reads pane fields with `IFS=$'\t' read`, and tab is IFS whitespace,
# so an empty #{pane_title} collapses and the ":dir" field lands in the title
# slot. restore.sh then cds into "1"/"0" (pane_active) and the pane opens in
# the server cwd. A well-formed line always has ":dir" in field 8. The repair
# cannot write an empty title (restore would collapse it again), so it uses
# tmux's default title, the hostname. The full command is dropped: save.sh
# derived it from the shifted history_size, not the pane pid.
PLACEHOLDER_TITLE=$(hostname 2>/dev/null || echo "tmux")

awk -F '\t' -v OFS='\t' -v title="$PLACEHOLDER_TITLE" '
  # FILENAME, not NR == FNR: the keys file is empty when no sidebars exist.
  FILENAME == ARGV[1] {
    sidebar[$1 "\t" $2 "\t" $3] = 1
    next
  }
  $1 == "pane" && $8 !~ /^:/ && $7 ~ /^:/ {
    $0 = $1 OFS $2 OFS $3 OFS $4 OFS $5 OFS $6 OFS title OFS $7 OFS $8 OFS $9 OFS ":"
  }
  $1 == "pane" && (($2 "\t" $3 "\t" $6) in sidebar) {
    next
  }
  { print }
' "$KEYS_FILE" "$SAVE_FILE" >"$TMP_FILE"

if ! cmp -s "$TMP_FILE" "$SAVE_FILE"; then
  mv "$TMP_FILE" "$SAVE_FILE"
fi
