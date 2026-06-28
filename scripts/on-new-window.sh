#!/usr/bin/env bash
# On new window: optional fzf repo picker to add a tree and cd the window.

set -euo pipefail

SESSION="${1:-}"
WINDOW="${2:-}"
PANE="${3:-}"
if [[ -z "$SESSION" || -z "$WINDOW" ]]; then
  exit 0
fi

SCRIPTS_DIR="${TMUXR_SCRIPTS_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"
WORKCTL_BIN=$(tmux show-environment -g WORKCTL_BIN 2>/dev/null | cut -d= -f2- || true)
if [[ -z "$WORKCTL_BIN" ]]; then
  exit 0
fi

PROMPT=$($WORKCTL_BIN config get prompt-repos-on-new-window 2>/dev/null || echo "false")
if [[ "$PROMPT" != "true" ]]; then
  exit 0
fi

SCAN_DIRS=$($WORKCTL_BIN config get repo-scan-dir 2>/dev/null || echo "")
if [[ -z "$SCAN_DIRS" ]]; then
  exit 0
fi

if ! $WORKCTL_BIN session is-tracked "$SESSION" --quiet 2>/dev/null; then
  exit 0
fi

ACTIVE_PANE="$PANE"
if [[ -z "$ACTIVE_PANE" ]]; then
  while IFS=$'\t' read -r pane_id active; do
    if [[ "$active" == "1" && -n "$pane_id" ]]; then
      ACTIVE_PANE="$pane_id"
      break
    fi
  done < <(tmux list-panes -t "$WINDOW" -F "#{pane_id}\t#{pane_active}" 2>/dev/null || true)
fi

if [[ -z "$ACTIVE_PANE" ]]; then
  ACTIVE_PANE=$(tmux list-panes -t "$WINDOW" -F '#{pane_id}' 2>/dev/null | head -1 || true)
fi

if [[ -z "$ACTIVE_PANE" ]]; then
  exit 0
fi

SIDEBAR=$(tmux show-option -p -t "$ACTIVE_PANE" -v @workctl-sidebar 2>/dev/null || echo "")
if [[ "$SIDEBAR" == "1" ]]; then
  exit 0
fi

REPO_COUNT=$($WORKCTL_BIN repos --format names 2>/dev/null | grep -c . || true)
if [[ "$REPO_COUNT" -eq 0 ]]; then
  tmux display-message -d 4000 "workctl: no repos in repo-scan-dir"
  exit 0
fi

bash "$SCRIPTS_DIR/repo-picker-window-inner.sh" "$SESSION" "$WINDOW"
