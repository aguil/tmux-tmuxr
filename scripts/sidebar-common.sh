#!/usr/bin/env bash
# Shared sidebar helpers for tmux-tmuxr scripts.

sidebar_common_dir() {
  cd "$(dirname "${BASH_SOURCE[1]:-${BASH_SOURCE[0]}}")" && pwd
}

work_session_tracked() {
  local session="$1"
  tmux show-option -t "$session" -v @work-workspace &>/dev/null
}

work_sidebar_visible() {
  local session="$1"
  local disabled visible

  disabled=$(tmux show-option -t "$session" -qv @work-sidebar-disabled 2>/dev/null || echo "")
  if [[ "$disabled" == "1" ]]; then
    return 1
  fi

  visible=$(tmux show-option -t "$session" -qv @work-sidebar-visible 2>/dev/null || echo "")
  if [[ "$visible" == "0" ]]; then
    return 1
  fi

  return 0
}

work_set_sidebar_visible() {
  local session="$1"
  local visible="$2"

  if [[ "$visible" == "1" ]]; then
    tmux set-option -t "$session" -u @work-sidebar-disabled 2>/dev/null || true
    tmux set-option -t "$session" @work-sidebar-visible 1
  else
    tmux set-option -t "$session" @work-sidebar-visible 0
    tmux set-option -t "$session" @work-sidebar-disabled 1
  fi
}

work_kill_session_sidebars() {
  local session="$1"
  local pane_id

  while IFS= read -r pane_id; do
    [[ -z "$pane_id" ]] && continue
    tmux kill-pane -t "$pane_id" 2>/dev/null || true
  done < <(
    tmux list-panes -s -t "$session" -F '#{pane_id}	#{@work-sidebar}' 2>/dev/null |
      awk -F'\t' '$2 == "1" { print $1 }'
  )
}

work_repair_session_sidebars() {
  local session="$1"
  local work_bin pane_id dead marked

  if ! work_session_tracked "$session"; then
    return 0
  fi

  work_bin=$(tmux show-environment -g WORK_BIN 2>/dev/null | cut -d= -f2- || true)
  if [[ -z "$work_bin" ]]; then
    return 0
  fi

  if ! work_sidebar_visible "$session"; then
    work_kill_session_sidebars "$session"
    return 0
  fi

  while IFS=$'\t' read -r pane_id dead marked cmd; do
    if [[ "$dead" != "1" ]]; then
      continue
    fi
    if [[ "$marked" == "1" || "$cmd" == *sidebar* ]]; then
      tmux respawn-pane -k -t "$pane_id" "${work_bin} sidebar" 2>/dev/null ||
        tmux kill-pane -t "$pane_id" 2>/dev/null || true
    fi
  done < <(
    tmux list-panes -t "$session" -F '#{pane_id}	#{pane_dead}	#{@work-sidebar}	#{pane_current_command}' 2>/dev/null || true
  )

  local window_target
  while IFS= read -r window_target; do
    [[ -z "$window_target" ]] && continue
    bash "$(sidebar_common_dir)/ensure-sidebar.sh" "$window_target" 2>/dev/null || true
  done < <(
    tmux list-windows -t "$session" -F '#{session_name}:#{window_index}' 2>/dev/null || true
  )
}

work_ensure_session_sidebars() {
  local session="$1"
  local window_target

  if ! work_session_tracked "$session"; then
    return 0
  fi

  if ! work_sidebar_visible "$session"; then
    return 0
  fi

  while IFS= read -r window_target; do
    [[ -z "$window_target" ]] && continue
    bash "$(sidebar_common_dir)/ensure-sidebar.sh" "$window_target" 2>/dev/null || true
  done < <(
    tmux list-windows -t "$session" -F '#{session_name}:#{window_index}' 2>/dev/null || true
  )
}
