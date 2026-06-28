#!/usr/bin/env bash
# tmux-tmuxr TPM plugin entry point
# Sets hooks, keybindings, and starts the workctld daemon.

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$CURRENT_DIR/scripts"

# Resolve workctl and workctld binaries.
# Prefer local development build, then global install.
resolve_bin() {
    local name="$1"
    local dev_path="$CURRENT_DIR/../workctl/dist/${name}.mjs"
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

WORKCTL=$(resolve_bin "workctl")
WORKCTLD=$(resolve_bin "workctld")

if [[ -z "$WORKCTL" ]]; then
    tmux display-message "tmux-tmuxr: workctl not found"
    exit 1
fi

# Export for use by hook scripts
tmux set-environment -g WORKCTL_BIN "$WORKCTL"
tmux set-environment -g WORKCTLD_BIN "$WORKCTLD"
tmux set-environment -g TMUXR_SCRIPTS_DIR "$SCRIPTS_DIR"

# --- Daemon lifecycle ---

if [[ -n "$WORKCTLD" ]]; then
    bash "$SCRIPTS_DIR/start-daemon.sh"
fi

# --- Hooks (all use -ga to append, run-shell -b for non-blocking) ---

# Agent auto-detection on new panes/windows
tmux set-hook -ga after-split-window \
    "run-shell -b '$WORKCTL scan --session #{session_name} --quiet 2>/dev/null || true'"

# Scan + optional repo picker (replace on each plugin load to avoid duplicate hooks)
tmux set-hook -g after-new-window \
    "run-shell 'bash \"$SCRIPTS_DIR/after-new-window.sh\" #{session_name} #{window_id} #{pane_id} 2>/dev/null || true'"

# Orphan cleanup when panes exit
tmux set-hook -ga pane-exited \
    "run-shell -b '$WORKCTL agent detach #{hook_pane} --quiet 2>/dev/null || true'"

# Archive workspace when session closes
tmux set-hook -ga session-closed \
    "run-shell -b '$WORKCTL untrack #{hook_session_name} --auto --quiet 2>/dev/null || true'"

# Reconcile on client attach (replace hook on reload; clears legacy attach pickers)
tmux set-hook -g client-attached \
    "run-shell -b 'bash \"$SCRIPTS_DIR/on-client-attached.sh\" #{session_name}; $WORKCTL reconcile --all --quiet 2>/dev/null || true'"

# Pane title changes (tmux 3.5+ only)
TMUX_VERSION=$(tmux -V | sed 's/[^0-9.]//g')
if awk "BEGIN { exit !($TMUX_VERSION >= 3.5) }"; then
    tmux set-hook -ga pane-title-changed \
        "run-shell -b '$WORKCTL agent title-changed #{pane_id} --quiet 2>/dev/null || true'"
fi

# Auto-track on session creation (opt-in via workctl config; no tmux reload needed)
tmux set-hook -ga session-created \
    "run-shell -b 'bash \"$SCRIPTS_DIR/on-session-created.sh\" #{session_name} 2>/dev/null || true'"

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
