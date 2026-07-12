#!/usr/bin/env bash
# tmux-tmuxr TPM plugin entry point
# Sets hooks, keybindings, and starts the workd daemon.

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$CURRENT_DIR/scripts"
MIN_WORK_VERSION="0.1.0"

TMUXR_VERSION=""
if [[ -f "$CURRENT_DIR/VERSION" ]]; then
    TMUXR_VERSION="$(tr -d '[:space:]' <"$CURRENT_DIR/VERSION")"
fi

# Resolve work and workd binaries.
# Prefer local development build, then global install.
resolve_bin() {
    local name="$1"
    local dev_path="$CURRENT_DIR/../work/dist/${name}.mjs"
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

WORK=$(resolve_bin "work")
WORKD=$(resolve_bin "workd")

if [[ -z "$WORK" ]]; then
    tmux display-message "tmux-tmuxr: work not found (npm install -g @aguil/work)"
    exit 1
fi

read -r -a WORK_CMD <<<"$WORK"
WORK_VER=$("${WORK_CMD[@]}" --version 2>/dev/null | tr -d '[:space:]' || true)
if [[ -n "$WORK_VER" ]] &&
    [[ "$(printf '%s\n' "$MIN_WORK_VERSION" "$WORK_VER" | sort -V | head -1)" != "$MIN_WORK_VERSION" ]]; then
    tmux display-message \
        "tmux-tmuxr: work $WORK_VER < $MIN_WORK_VERSION (npm install -g @aguil/work)"
    exit 1
fi

# Export for use by hook scripts
tmux set-environment -g WORK_BIN "$WORK"
tmux set-environment -g WORKD_BIN "$WORKD"
tmux set-environment -g TMUXR_SCRIPTS_DIR "$SCRIPTS_DIR"
if [[ -n "$TMUXR_VERSION" ]]; then
    tmux set-environment -g TMUXR_VERSION "$TMUXR_VERSION"
fi

TMUXR_SIDEBAR_WIDTH=$($WORK config get sidebar-width 2>/dev/null || echo "40")
TMUXR_SIDEBAR_POSITION=$($WORK config get sidebar-position 2>/dev/null || echo "right")
tmux set-environment -g TMUXR_SIDEBAR_WIDTH "$TMUXR_SIDEBAR_WIDTH"
tmux set-environment -g TMUXR_SIDEBAR_POSITION "$TMUXR_SIDEBAR_POSITION"

# Mark tmux-resurrect restores so new-window hooks do not prompt for repos
# while saved sessions/windows are being recreated.
tmux set-option -gq @resurrect-hook-post-save-layout \
    "bash \"$SCRIPTS_DIR/filter-resurrect-save.sh\""
tmux set-option -gq @resurrect-hook-pre-restore-all \
    "tmux set-option -gq @work-restoring 1; tmux set-option -gqu @work-restore-finished-at"
tmux set-option -gq @resurrect-hook-post-restore-all \
    "bash \"$SCRIPTS_DIR/on-post-restore.sh\""

# --- Daemon lifecycle ---

if [[ -n "$WORKD" ]]; then
    bash "$SCRIPTS_DIR/start-daemon.sh"
fi

# --- Hooks (replace on plugin reload; run-shell -b for non-blocking) ---

# Agent auto-detection on new panes/windows
tmux set-hook -g after-split-window \
    "run-shell -b '$WORK scan --pane #{pane_id} --quiet 2>/dev/null || true'"

# Scan + optional repo picker (replace on each plugin load to avoid duplicate hooks)
tmux set-hook -g after-new-window \
    "run-shell -b 'bash \"$SCRIPTS_DIR/after-new-window.sh\" #{window_id} #{pane_id} 2>/dev/null || true'"

# Orphan cleanup when panes exit
tmux set-hook -g pane-exited \
    "run-shell -b '$WORK agent detach #{hook_pane} --quiet 2>/dev/null || true'"

# Archive workspace when session closes
tmux set-hook -g session-closed \
    "run-shell -b 'bash \"$SCRIPTS_DIR/on-session-closed.sh\" #{hook_session} 2>/dev/null || true'"

# Reconcile on client attach (replace hook on reload; clears legacy attach pickers)
tmux set-hook -g client-attached \
    "run-shell -b 'bash \"$SCRIPTS_DIR/on-client-attached.sh\" #{hook_session}; bash \"$SCRIPTS_DIR/restore-window-format.sh\" 2>/dev/null || true; $WORK reconcile --all --quiet 2>/dev/null || true'"

# Restore sidebar width after terminal/display resize (e.g. disconnect external monitor)
tmux set-hook -g client-resized \
    "run-shell -b 'bash \"$SCRIPTS_DIR/resize-sidebars.sh\" 2>/dev/null || true'"


# Pane title changes (tmux 3.5+ only)
TMUX_VERSION=$(tmux -V | sed 's/[^0-9.]//g')
if awk "BEGIN { exit !($TMUX_VERSION >= 3.5) }"; then
    tmux set-hook -g pane-title-changed \
        "run-shell -b '$WORK agent title-changed #{pane_id} --quiet 2>/dev/null || true'"
fi

# Auto-track on session creation (opt-in via work config; no tmux reload needed)
tmux set-hook -g session-created \
    "run-shell -b 'bash \"$SCRIPTS_DIR/on-session-created.sh\" #{hook_session} 2>/dev/null || true'"

# --- Keybindings ---

# prefix + W: toggle sidebar (uppercase; lowercase w is choose-tree)
tmux bind-key W run-shell "bash '$SCRIPTS_DIR/sidebar-toggle.sh'"

# prefix + S: track current session + scan
tmux bind-key S run-shell "bash '$SCRIPTS_DIR/track-session.sh'"

# --- Sidebar in existing windows ---
# Create sidebar in all existing windows if not already present
bash "$SCRIPTS_DIR/ensure-all-sidebars.sh" &

# --- Status-line integration ---
# Users can add this to their status-right:
#   set -g status-right '#($SCRIPTS_DIR/status.sh)'

bash "$SCRIPTS_DIR/restore-window-format.sh"
