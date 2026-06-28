#!/usr/bin/env bash
# Run inside tmux display-popup; fzf picks an action id to run.

set -euo pipefail

SESSION="${1:-}"
if [[ -z "$SESSION" ]]; then
  exit 0
fi

SCRIPTS_DIR="${TMUXR_SCRIPTS_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"
WORKCTL_BIN=$(tmux show-environment -g WORKCTL_BIN 2>/dev/null | cut -d= -f2- || true)
if [[ -z "$WORKCTL_BIN" ]]; then
  exit 1
fi

if ! command -v fzf >/dev/null 2>&1; then
  tmux display-message -d 4000 "workctl: fzf is required for the action picker"
  exit 1
fi

pick=$(
  $WORKCTL_BIN action list --session "$SESSION" --format tsv 2>/dev/null |
    bash "$SCRIPTS_DIR/fzf-tmuxr.sh" \
      --with-nth=3,1 --delimiter=$'\t' --prompt="action> " \
      --preview 'echo {}' --preview-window=down:1 || true
)

if [[ -z "$pick" ]]; then
  exit 0
fi

action_id="${pick%%$'\t'*}"
$WORKCTL_BIN action run "$action_id" --session "$SESSION" --quiet
