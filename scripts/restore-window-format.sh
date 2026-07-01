#!/usr/bin/env bash
# Reset window tab format to tokyo-night defaults (no per-window agent icons).
# Called from append-status.sh, tmux-tmuxr.tmux, and on client attach.

set -euo pipefail

PLUGIN="${TOKYO_NIGHT_PLUGIN:-$HOME/.tmux/plugins/tokyo-night-tmux}"
SCRIPTS_PATH="$PLUGIN/src"

strip_injections() {
  local option fmt stripped
  for option in window-status-format window-status-current-format; do
    fmt="$(tmux show -gv "$option" 2>/dev/null || true)"
    [[ -z "$fmt" ]] && continue
    stripped="$(printf '%s' "$fmt" | sed -E \
      -e "s|[[:space:]]*#\\([^)]*tmux-tmuxr[^)]*\\)||g" \
      -e "s|[[:space:]]*#\\([^)]*window-agent-status[^)]*\\)||g" \
      -e "s|[[:space:]]*#\\([^)]*work[^)]*status[^)]*\\)||g" \
      -e "s|[[:space:]]*#\\([^)]*format icon[^)]*\\)||g")"
    stripped="${stripped//\#\{?\#\{==:\#\{pane_current_command\},agent\}, ,\#\{?\#\{==:\#\{pane_current_command\},ssh\},󰣀 ,  \}\}/\#\{?\#\{==:\#\{pane_current_command\},ssh\},󰣀 ,  \}}"
    if [[ "$stripped" != "$fmt" ]]; then
      tmux set -g "$option" "$stripped"
    fi
  done
}

if [[ ! -d "$SCRIPTS_PATH" ]]; then
  strip_injections
  exit 0
fi

tmux_option() {
  local name=$1
  local default=$2
  local value
  value="$(tmux show -gv "$name" 2>/dev/null || true)"
  if [[ -n "$value" && "$value" != *"No such option"* ]]; then
    printf '%s' "$value"
  else
    printf '%s' "$default"
  fi
}

theme="$(tmux_option '@tokyo-night-tmux_theme' 'night')"
case "$theme" in
  storm)
    background="#24283b"
    foreground="#a9b1d6"
    green="#73daca"
    bblack="#414868"
    yellow="#e0af68"
    ;;
  moon)
    background="#222436"
    foreground="#828bb8"
    green="#4fd6be"
    bblack="#444a73"
    yellow="#e0af68"
    ;;
  day)
    background="#d0d5e3"
    foreground="#6172b0"
    green="#41a6b5"
    bblack="#a8aecb"
    yellow="#8c6c3e"
    ;;
  *)
    background="#1A1B26"
    foreground="#a9b1d6"
    green="#73daca"
    bblack="#2A2F41"
    yellow="#e0af68"
    ;;
esac

window_id_style="$(tmux_option '@tokyo-night-tmux_window_id_style' 'digital')"
pane_id_style="$(tmux_option '@tokyo-night-tmux_pane_id_style' 'hsquare')"
zoom_id_style="$(tmux_option '@tokyo-night-tmux_zoom_id_style' 'dsquare')"

RESET="#[fg=${foreground},bg=${background},nobold,noitalics,nounderscore,nodim]"
window_number="#($SCRIPTS_PATH/custom-number.sh #I $window_id_style)"
custom_pane="#($SCRIPTS_PATH/custom-number.sh #P $pane_id_style)"
zoom_number="#($SCRIPTS_PATH/custom-number.sh #P $zoom_id_style)"

current_format="#[fg=${foreground}] #{?#{==:#{pane_current_command},ssh},󰣀 ,  }${RESET}$window_number#W#[nobold,dim]#{?window_zoomed_flag, $zoom_number, $custom_pane}#[default]#{?window_last_flag, , }"
current_current_format="#[fg=${green},bg=${bblack}] #{?#{==:#{pane_current_command},ssh},󰣀 ,  }#[fg=${foreground},bold,nodim]$window_number#W#[nobold]#{?window_zoomed_flag, $zoom_number, $custom_pane}#[default]#{?window_last_flag, , }"

tmux set -g window-status-format "$RESET$current_format"
tmux set -g window-status-current-format "$RESET$current_current_format"
