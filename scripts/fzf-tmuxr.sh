#!/usr/bin/env bash
# fzf via tmux popup (--tmux). Do not nest inside display-popup.

set -euo pipefail

exec fzf \
  --tmux "${FZF_TMUXR_POPUP:-center,80%,60%}" \
  --no-mouse \
  --bind 'esc:abort,ctrl-c:abort,ctrl-g:abort' \
  "$@"
