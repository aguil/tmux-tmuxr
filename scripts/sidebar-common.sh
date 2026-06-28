#!/usr/bin/env bash
# Shared sidebar helpers for tmux-tmuxr scripts.

sidebar_common_dir() {
  cd "$(dirname "${BASH_SOURCE[1]:-${BASH_SOURCE[0]}}")" && pwd
}

workctl_session_tracked() {
  local session="$1"
  tmux show-option -t "$session" -v @workctl-workspace &>/dev/null
}

workctl_sidebar_visible() {
  local session="$1"
  local disabled visible

  disabled=$(tmux show-option -t "$session" -qv @workctl-sidebar-disabled 2>/dev/null || echo "")
  if [[ "$disabled" == "1" ]]; then
    return 1
  fi

  visible=$(tmux show-option -t "$session" -qv @workctl-sidebar-visible 2>/dev/null || echo "")
  if [[ "$visible" == "0" ]]; then
    return 1
  fi

  return 0
}

workctl_set_sidebar_visible() {
  local session="$1"
  local visible="$2"

  if [[ "$visible" == "1" ]]; then
    tmux set-option -t "$session" -u @workctl-sidebar-disabled 2>/dev/null || true
    tmux set-option -t "$session" @workctl-sidebar-visible 1
  else
    tmux set-option -t "$session" @workctl-sidebar-visible 0
    tmux set-option -t "$session" @workctl-sidebar-disabled 1
  fi
}

workctl_kill_session_sidebars() {
  local session="$1"
  local pane_id

  while IFS= read -r pane_id; do
    [[ -z "$pane_id" ]] && continue
    tmux kill-pane -t "$pane_id" 2>/dev/null || true
  done < <(
    tmux list-panes -t "$session" -F '#{pane_id}	#{@workctl-sidebar}' 2>/dev/null |
      awk -F'\t' '$2 == "1" { print $1 }'
  )
}

workctl_repair_session_sidebars() {
  local session="$1"
  local workctl_bin pane_id dead marked

  if ! workctl_session_tracked "$session"; then
    return 0
  fi

  workctl_bin=$(tmux show-environment -g WORKCTL_BIN 2>/dev/null | cut -d= -f2- || true)
  if [[ -z "$workctl_bin" ]]; then
    return 0
  fi

  if ! workctl_sidebar_visible "$session"; then
    workctl_kill_session_sidebars "$session"
    return 0
  fi

  while IFS=$'\t' read -r pane_id dead marked cmd; do
    if [[ "$dead" != "1" ]]; then
      continue
    fi
    if [[ "$marked" == "1" || "$cmd" == *sidebar* ]]; then
      tmux respawn-pane -k -t "$pane_id" "${workctl_bin} sidebar" 2>/dev/null ||
        tmux kill-pane -t "$pane_id" 2>/dev/null || true
    fi
  done < <(
    tmux list-panes -t "$session" -F '#{pane_id}	#{pane_dead}	#{@workctl-sidebar}	#{pane_current_command}' 2>/dev/null || true
  )

  local window_target
  while IFS= read -r window_target; do
    [[ -z "$window_target" ]] && continue
    bash "$(sidebar_common_dir)/ensure-sidebar.sh" "$window_target" 2>/dev/null || true
  done < <(
    tmux list-windows -t "$session" -F '#{session_name}:#{window_index}' 2>/dev/null || true
  )
}

workctl_ensure_session_sidebars() {
  local session="$1"
  local window_target

  if ! workctl_session_tracked "$session"; then
    return 0
  fi

  if ! workctl_sidebar_visible "$session"; then
    return 0
  fi

  while IFS= read -r window_target; do
    [[ -z "$window_target" ]] && continue
    bash "$(sidebar_common_dir)/ensure-sidebar.sh" "$window_target" 2>/dev/null || true
  done < <(
    tmux list-windows -t "$session" -F '#{session_name}:#{window_index}' 2>/dev/null || true
  )
}
