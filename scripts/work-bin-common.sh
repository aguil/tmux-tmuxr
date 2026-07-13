#!/usr/bin/env bash
# Shared work/workd binary resolution for tmux-tmuxr scripts.

resolve_bin() {
  local name="$1"
  local plugin_dir option dev_path

  plugin_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  option=$(tmux show-option -gqv "@${name}-bin" 2>/dev/null || true)
  if [[ -n "$option" ]]; then
    echo "$option"
    return
  fi
  dev_path="$plugin_dir/../work/dist/${name}.mjs"
  if [[ -x "$dev_path" ]] || [[ -f "$dev_path" ]]; then
    echo "node $dev_path"
    return
  fi
  if command -v "$name" &>/dev/null; then
    echo "$name"
    return
  fi
  echo ""
}
