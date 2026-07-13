#!/usr/bin/env bash
# Shared work/workd binary resolution for tmux-tmuxr scripts.

MIN_WORK_VERSION="${MIN_WORK_VERSION:-0.1.0}"

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

work_bin_version() {
  local work_bin="$1"
  local -a work_cmd

  read -r -a work_cmd <<<"$work_bin"
  "${work_cmd[@]}" --version 2>/dev/null | tr -d '[:space:]' || true
}

work_meets_min_version() {
  local work_bin="$1"
  local min_version="${2:-$MIN_WORK_VERSION}"
  local work_ver

  work_ver=$(work_bin_version "$work_bin")
  if [[ -z "$work_ver" ]]; then
    return 0
  fi
  [[ "$(printf '%s\n' "$min_version" "$work_ver" | sort -V | head -1)" == "$min_version" ]]
}
