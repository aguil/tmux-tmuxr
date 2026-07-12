#!/usr/bin/env bash
# Shared sidebar helpers for tmux-tmuxr scripts.

sidebar_common_dir() {
  cd "$(dirname "${BASH_SOURCE[1]:-${BASH_SOURCE[0]}}")" && pwd
}

work_sidebar_config_width() {
  local work_bin width

  width=$(tmux show-environment -g TMUXR_SIDEBAR_WIDTH 2>/dev/null | cut -d= -f2- || true)
  if [[ -n "$width" ]]; then
    echo "$width"
    return
  fi

  work_bin=$(tmux show-environment -g WORK_BIN 2>/dev/null | cut -d= -f2- || true)
  if [[ -n "$work_bin" ]]; then
    width=$($work_bin config get sidebar-width 2>/dev/null || echo "40")
    tmux set-environment -g TMUXR_SIDEBAR_WIDTH "$width" 2>/dev/null || true
    echo "$width"
    return
  fi

  echo "40"
}

work_sidebar_config_position() {
  local work_bin position

  position=$(tmux show-environment -g TMUXR_SIDEBAR_POSITION 2>/dev/null | cut -d= -f2- || true)
  if [[ -n "$position" ]]; then
    echo "$position"
    return
  fi

  work_bin=$(tmux show-environment -g WORK_BIN 2>/dev/null | cut -d= -f2- || true)
  if [[ -n "$work_bin" ]]; then
    position=$($work_bin config get sidebar-position 2>/dev/null || echo "right")
    tmux set-environment -g TMUXR_SIDEBAR_POSITION "$position" 2>/dev/null || true
    echo "$position"
    return
  fi

  echo "right"
}

work_refresh_sidebar_config_cache() {
  local work_bin width position

  work_bin=$(tmux show-environment -g WORK_BIN 2>/dev/null | cut -d= -f2- || true)
  if [[ -z "$work_bin" ]]; then
    return 0
  fi

  width=$($work_bin config get sidebar-width 2>/dev/null || echo "40")
  position=$($work_bin config get sidebar-position 2>/dev/null || echo "right")
  tmux set-environment -g TMUXR_SIDEBAR_WIDTH "$width"
  tmux set-environment -g TMUXR_SIDEBAR_POSITION "$position"
}

work_session_tracked() {
  local session="$1"
  local work_bin

  if tmux show-option -t "$session" -v @work-workspace &>/dev/null; then
    return 0
  fi

  work_bin=$(tmux show-environment -g WORK_BIN 2>/dev/null | cut -d= -f2- || true)
  if [[ -z "$work_bin" ]]; then
    return 1
  fi

  if $work_bin session hydrate "$session" --quiet 2>/dev/null; then
    return 0
  fi
  return 1
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

work_ensure_sidebar_windows() {
  local session="$1"
  local active_window="$2"
  local window_target

  if [[ -n "$active_window" ]]; then
    bash "$(sidebar_common_dir)/ensure-sidebar.sh" "$active_window" 2>/dev/null || true
  fi

  while IFS= read -r window_target; do
    [[ -z "$window_target" || "$window_target" == "$active_window" ]] && continue
    bash "$(sidebar_common_dir)/ensure-sidebar.sh" "$window_target" 2>/dev/null &
  done < <(
    tmux list-windows -t "$session" -F '#{session_name}:#{window_index}' 2>/dev/null || true
  )
}

work_resize_all_sidebars() {
  local target_width window_width pane_width width min_main min_sidebar work_bin

  work_bin=$(tmux show-environment -g WORK_BIN 2>/dev/null | cut -d= -f2- || true)
  if [[ -z "$work_bin" ]]; then
    return 0
  fi

  work_refresh_sidebar_config_cache
  target_width=$(work_sidebar_config_width)
  min_main=40
  min_sidebar=24

  while IFS=$'\t' read -r pane_id session_name dead marked window_width pane_width; do
    [[ "$marked" != "1" || "$dead" == "1" ]] && continue
    if ! work_sidebar_visible "$session_name"; then
      continue
    fi

    width=$target_width
    if [[ "$window_width" =~ ^[0-9]+$ ]]; then
      if (( window_width - min_main < min_sidebar )); then
        continue
      fi
      if (( width > window_width - min_main )); then
        width=$((window_width - min_main))
      fi
    fi
    if [[ "$pane_width" =~ ^[0-9]+$ ]] && (( pane_width == width )); then
      continue
    fi

    tmux resize-pane -t "$pane_id" -x "$width" 2>/dev/null || true
  done < <(
    tmux list-panes -a -F '#{pane_id}	#{session_name}	#{pane_dead}	#{@work-sidebar}	#{window_width}	#{pane_width}' 2>/dev/null || true
  )
}

work_repair_session_sidebars() {
  local session="$1"
  local work_bin pane_id dead marked active_window

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

  active_window=$(tmux display-message -p -t "$session" '#{session_name}:#{window_index}' 2>/dev/null || true)
  work_ensure_sidebar_windows "$session" "$active_window"
  work_resize_all_sidebars
}

work_ensure_session_sidebars() {
  local session="$1"
  local active_window

  if ! work_session_tracked "$session"; then
    return 0
  fi

  if ! work_sidebar_visible "$session"; then
    return 0
  fi

  active_window=$(tmux display-message -p -t "$session" '#{session_name}:#{window_index}' 2>/dev/null || true)
  work_ensure_sidebar_windows "$session" "$active_window"
  work_resize_all_sidebars
}
