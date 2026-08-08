#!/usr/bin/env bash
# One-time teardown of legacy status-line injections.
#
# Versions <= 0.1.3 prepended a segment to status-right and rewrote
# window-status-format from a hardcoded theme palette. Both options are
# theme-owned; tmuxr no longer writes them. This strips what those versions
# left behind in a running server, once, then marks itself done.
#
# Temporary: delete this script and its call site in tmux-tmuxr.tmux after a
# release or two.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/tmux-tmuxr"
MARKER="$STATE_DIR/status-teardown-done"

if [[ -f "$MARKER" ]]; then
  exit 0
fi

changed=0

# status-right: remove only the exact literal the old injector wrote, so a
# user-authored segment (README form: unquoted ~ path) is left untouched.
legacy="#(bash '$SCRIPT_DIR/status.sh') "
sr="$(tmux show -gv status-right 2>/dev/null || true)"
if [[ "$sr" == "$legacy"* ]]; then
  tmux set -g status-right "${sr#"$legacy"}"
  changed=1
fi

# Window formats: strip dead #() references to scripts this plugin no longer
# ships. Theme-owned content is left as-is; the theme reasserts it on reload.
for option in window-status-format window-status-current-format; do
  fmt="$(tmux show -gv "$option" 2>/dev/null || true)"
  [[ -z "$fmt" ]] && continue
  stripped="$(printf '%s' "$fmt" | sed -E \
    -e "s|[[:space:]]*#\\([^)]*tmux-tmuxr[^)]*\\)||g" \
    -e "s|[[:space:]]*#\\([^)]*window-agent-status[^)]*\\)||g")"
  if [[ "$stripped" != "$fmt" ]]; then
    tmux set -g "$option" "$stripped"
    changed=1
  fi
done

if [[ "$changed" -eq 1 ]]; then
  tmux refresh-client -S 2>/dev/null || true
fi

mkdir -p "$STATE_DIR"
touch "$MARKER"
