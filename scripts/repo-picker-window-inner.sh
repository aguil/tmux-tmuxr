#!/usr/bin/env bash
# Run inside tmux display-popup; fzf picks one repo for the new window.

set -euo pipefail

SESSION="${1:-}"
WINDOW="${2:-}"
if [[ -z "$SESSION" || -z "$WINDOW" ]]; then
  exit 0
fi

SCRIPTS_DIR="${TMUXR_SCRIPTS_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"
WORK_BIN=$(tmux show-environment -g WORK_BIN 2>/dev/null | cut -d= -f2- || true)
if [[ -z "$WORK_BIN" ]]; then
  exit 1
fi

if ! command -v fzf >/dev/null 2>&1; then
  tmux display-message -d 4000 "work: fzf is required for the repo picker"
  exit 1
fi

FZF_OPTS=(
  --delimiter=$'\t'
  --with-nth='3,2,1'
  --prompt="repo> "
  --header="Pick a repo for this window (Esc to skip)"
)

selected=$(
  $WORK_BIN repos --format tsv 2>/dev/null |
    bash "$SCRIPTS_DIR/fzf-tmuxr.sh" "${FZF_OPTS[@]}" || true
)

if [[ -z "$selected" ]]; then
  exit 0
fi

path="${selected%%$'\t'*}"
if $WORK_BIN window use-repo "$path" --session "$SESSION" --window "$WINDOW" --quiet; then
  name=$(basename "$path")
  tmux display-message -d 3000 "work: $name → $path"
fi
