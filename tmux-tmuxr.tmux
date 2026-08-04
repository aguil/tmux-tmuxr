#!/usr/bin/env bash
# tmux-tmuxr TPM plugin entry point
# Sets hooks, keybindings, and starts the workd daemon.

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$CURRENT_DIR/scripts"

TMUXR_VERSION=""
if [[ -f "$CURRENT_DIR/VERSION" ]]; then
    TMUXR_VERSION="$(tr -d '[:space:]' <"$CURRENT_DIR/VERSION")"
fi

# Resolve work and workd binaries.
# Prefer local development build, then global install.
# shellcheck source=scripts/work-bin-common.sh
source "$SCRIPTS_DIR/work-bin-common.sh"

WORK=$(resolve_bin "work")
WORKD=$(resolve_bin "workd")

if [[ -z "$WORK" ]]; then
    tmux display-message "tmux-tmuxr: work not found (npm install -g @aguil/work)"
    exit 1
fi

if ! work_meets_min_version "$WORK"; then
    WORK_VER=$(work_bin_version "$WORK")
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

# --- Hooks (replace on plugin reload; non-blocking) ---
#
# Dispatch every hook with `if-shell -b <command> ''` rather than `run-shell -b`.
# When a background run-shell job exits non-zero, tmux writes "'<command>'
# returned N" into whatever pane is current and forces that pane into view mode
# -- which reads as a wedged client. A trailing `|| true` does not prevent it:
# tmux's job child exits 1 by itself when the server cannot spare a descriptor
# for the job, so the hook's shell never runs. if-shell inspects the status to
# pick a branch and prints nothing, so a failed hook stays contained. The empty
# then-branch is a no-op and there is no else-branch. See issue #15.

# Agent auto-detection on new panes/windows
tmux set-hook -g after-split-window \
    "if-shell -b '$WORK scan --pane #{pane_id} --quiet >/dev/null 2>&1' ''"

# Scan + optional repo picker (replace on each plugin load to avoid duplicate hooks)
tmux set-hook -g after-new-window \
    "if-shell -b 'bash \"$SCRIPTS_DIR/after-new-window.sh\" #{window_id} #{pane_id} >/dev/null 2>&1' ''"

# Orphan cleanup when panes exit
tmux set-hook -g pane-exited \
    "if-shell -b '$WORK agent detach #{hook_pane} --quiet >/dev/null 2>&1' ''"

# Archive workspace when session closes
tmux set-hook -g session-closed \
    "if-shell -b 'bash \"$SCRIPTS_DIR/on-session-closed.sh\" #{hook_session} >/dev/null 2>&1' ''"

# Reconcile on client attach (replace hook on reload; clears legacy attach pickers)
tmux set-hook -g client-attached \
    "if-shell -b '{ bash \"$SCRIPTS_DIR/on-client-attached.sh\" #{hook_session}; $WORK reconcile --all --quiet; } >/dev/null 2>&1' ''"

# Restore sidebar width after terminal/display resize (e.g. disconnect external
# monitor). The dispatcher only marks the resize pending; a detached worker
# debounces and resizes, so a drag cannot pile up concurrent tmux jobs.
tmux set-hook -g client-resized \
    "if-shell -b 'bash \"$SCRIPTS_DIR/resize-sidebars.sh\" >/dev/null 2>&1' ''"


# Pane title changes (tmux 3.5+ only). Agents rewrite their title constantly, so
# the hook queues the pane and one detached worker runs `work` serially.
TMUX_VERSION=$(tmux -V | sed 's/[^0-9.]//g')
if awk "BEGIN { exit !($TMUX_VERSION >= 3.5) }"; then
    tmux set-hook -g pane-title-changed \
        "if-shell -b 'bash \"$SCRIPTS_DIR/on-pane-title-changed.sh\" #{pane_id} >/dev/null 2>&1' ''"
fi

# Auto-track on session creation (opt-in via work config; no tmux reload needed)
tmux set-hook -g session-created \
    "if-shell -b 'bash \"$SCRIPTS_DIR/on-session-created.sh\" #{hook_session} >/dev/null 2>&1' ''"

# --- Keybindings ---

# prefix + W: toggle sidebar (uppercase; lowercase w is choose-tree)
tmux bind-key W run-shell "bash '$SCRIPTS_DIR/sidebar-toggle.sh'"

# prefix + S: track current session + scan
tmux bind-key S run-shell "bash '$SCRIPTS_DIR/track-session.sh'"

# --- Sidebar in existing windows ---
# Create sidebar in all existing windows if not already present. Detach it from
# this job's descriptors so tmux can close the job as soon as the plugin loads.
nohup bash "$SCRIPTS_DIR/ensure-all-sidebars.sh" </dev/null >/dev/null 2>&1 &

# --- Status line ---
# tmuxr does not write status-line options; the theme owns them. Users wire
# scripts/status.sh into their own config. See README.md ("Status line").

# Temporary: strip injections left by <= 0.1.3. Runs once per machine.
bash "$SCRIPTS_DIR/cleanup-status-injections.sh" 2>/dev/null || true
