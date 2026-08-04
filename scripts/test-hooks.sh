#!/usr/bin/env bash
# Regression coverage for issue #15: background hook failures must never be
# surfaced by tmux, and hook bursts must not pile up concurrent tmux jobs.
#
# Runs against a private tmux server; it does not touch the user's sessions.

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPTS_DIR="$ROOT/scripts"

# A tmux client prefers $TMUX over the socket implied by TMUX_TMPDIR, so running
# the suite from inside a session would otherwise let the dispatchers under test
# -- which invoke bare `tmux` -- reach the developer's own server and resize
# their real sidebars. Isolation has to start by dropping the inherited session.
unset TMUX TMUX_PANE

TMPROOT="$(mktemp -d "${TMPDIR:-/tmp}/tmuxr-test.XXXXXX")"
export TMUX_TMPDIR="$TMPROOT"
export XDG_RUNTIME_DIR="$TMPROOT"

FAILURES=0
SERVER_N=0
SOCKET=""
SOCKETS=()

# shellcheck disable=SC2317,SC2329  # invoked via trap; codes differ by version
cleanup() {
  local name
  for name in "${SOCKETS[@]+"${SOCKETS[@]}"}"; do
    tmux -L "$name" kill-server 2>/dev/null
  done
  rm -rf "$TMPROOT"
}
trap cleanup EXIT

tmux_test() { tmux -L "$SOCKET" "$@"; }

# Each case gets its own server on its own socket: a case that deliberately
# starves the server of descriptors must not leave the next one racing a
# half-dead one. Pass a socket name to override, e.g. "default" for a case whose
# code under test invokes bare `tmux`.
start_server() {
  local nofile="${1:-}"
  SERVER_N=$((SERVER_N + 1))
  SOCKET="${2:-tmuxr-t$$-$SERVER_N}"
  SOCKETS+=("$SOCKET")
  tmux -L "$SOCKET" kill-server 2>/dev/null
  sleep 0.2
  if [[ -n "$nofile" ]]; then
    bash -c "ulimit -n $nofile 2>/dev/null; exec tmux -L '$SOCKET' -f /dev/null new-session -d -s t 'sleep 600'"
  else
    tmux_test -f /dev/null new-session -d -s t 'sleep 600'
  fi
  sleep 0.3
}

pane_mode() { tmux_test display-message -p -t %0 '#{pane_mode}' 2>/dev/null; }

ok() { printf '  ok — %s\n' "$1"; }
fail() {
  printf '  FAIL — %s\n' "$1" >&2
  FAILURES=$((FAILURES + 1))
}

# --- 1. control: the old dispatch form does leak ------------------------------
# Guards the assertions below: if tmux ever stops dumping job failures into a
# pane, this test fails and the rest of the file is no longer meaningful.

printf 'run-shell -b surfaces a failing hook (control)\n'
start_server
tmux_test set-hook -g pane-title-changed "run-shell -b 'exit 1'"
tmux_test select-pane -t %0 -T "control"
sleep 1
if [[ "$(pane_mode)" == "view-mode" ]]; then
  ok "failing run-shell -b forces the pane into view mode"
else
  fail "expected run-shell -b to leak; harness can no longer detect regressions"
fi

# --- 2. the plugin's dispatch form contains failures --------------------------

printf 'if-shell -b contains a failing hook\n'
start_server
tmux_test set-hook -g pane-title-changed "if-shell -b 'exit 1' ''"
for i in $(seq 1 20); do tmux_test select-pane -t %0 -T "t$i"; done
sleep 1
if [[ -z "$(pane_mode)" ]]; then
  ok "failing if-shell -b leaves the pane untouched"
else
  fail "pane entered $(pane_mode) after a failing if-shell hook"
fi

# --- 3. containment survives descriptor exhaustion ----------------------------
# The reported failure: tmux's own job child exits 1 before the hook's shell
# runs, so `|| true` in the hook body cannot help.

printf 'if-shell -b contains tmux job failures under descriptor pressure\n'
start_server 96
tmux_test set-hook -g pane-title-changed "if-shell -b 'sleep 4 2>/dev/null || true' ''"
for i in $(seq 1 150); do tmux_test select-pane -t %0 -T "burst$i" 2>/dev/null; done
sleep 2
if [[ -z "$(pane_mode)" ]]; then
  ok "no pane output when the server runs out of descriptors"
else
  fail "pane entered $(pane_mode) under descriptor pressure"
fi

# --- 4. the title dispatcher coalesces and serialises -------------------------

printf 'pane-title-changed dispatcher coalesces bursts\n'
start_server
FAKE_WORK="$TMPROOT/fake-work"
CALL_LOG="$TMPROOT/calls.log"
cat >"$FAKE_WORK" <<EOF
#!/usr/bin/env bash
echo "+\$*" >>"$CALL_LOG"
sleep 0.2
echo "-" >>"$CALL_LOG"
EOF
chmod +x "$FAKE_WORK"
: >"$CALL_LOG"
tmux_test set-environment -g WORK_BIN "$FAKE_WORK"
tmux_test set-hook -g pane-title-changed \
  "if-shell -b 'bash \"$SCRIPTS_DIR/on-pane-title-changed.sh\" #{pane_id} >/dev/null 2>&1' ''"
for i in $(seq 1 40); do tmux_test select-pane -t %0 -T "burst$i"; done
sleep 3

calls=$(grep -c '^+' "$CALL_LOG" 2>/dev/null)
calls=${calls:-0}
if (( calls >= 1 && calls < 40 )); then
  ok "40 title events collapsed into $calls work invocations"
else
  fail "expected 1..39 work invocations for 40 events, got $calls"
fi

# No two invocations may overlap: every '+' is followed by its own '-'.
if awk '/^\+/ { if (open) { exit 1 } open = 1; next } /^-/ { open = 0 }' "$CALL_LOG"; then
  ok "work invocations never overlap"
else
  fail "overlapping work invocations — dispatcher is not single-flight"
fi

if [[ -z "$(pane_mode)" ]]; then
  ok "dispatcher left the pane untouched"
else
  fail "pane entered $(pane_mode) during the title burst"
fi

# --- 5. a deliberately failing handler is logged nowhere but stays contained --

printf 'a failing handler does not reach the client\n'
start_server
cat >"$FAKE_WORK" <<'EOF'
#!/usr/bin/env bash
echo "handler exploded" >&2
exit 3
EOF
chmod +x "$FAKE_WORK"
tmux_test set-environment -g WORK_BIN "$FAKE_WORK"
tmux_test set-hook -g pane-title-changed \
  "if-shell -b 'bash \"$SCRIPTS_DIR/on-pane-title-changed.sh\" #{pane_id} >/dev/null 2>&1' ''"
for i in $(seq 1 10); do tmux_test select-pane -t %0 -T "boom$i"; done
sleep 2
if [[ -z "$(pane_mode)" ]] && ! tmux_test show-messages 2>/dev/null | grep -q "returned"; then
  ok "handler failure never reached the pane or the message log"
else
  fail "failing handler surfaced to the client"
fi

# --- 6. the resize dispatcher is single-flight --------------------------------

printf 'client-resized dispatcher is single-flight\n'
# The dispatcher and its worker invoke bare `tmux`, which resolves to the
# default socket under TMUX_TMPDIR -- so this case puts its server there and
# populates the environment work_resize_all_sidebars reads. Otherwise the worker
# reaches no server, returns immediately, and the assertion below measures
# nothing.
start_server "" default
tmux_test set-environment -g WORK_BIN /bin/true
tmux_test set-environment -g TMUXR_SIDEBAR_WIDTH 40

# Sample during the burst, not after: a worker that has already exited is
# indistinguishable from one that never spawned.
(
  for _ in $(seq 1 40); do
    n=$(pgrep -fc "resize-sidebars[.]sh --drain" 2>/dev/null)
    printf '%s\n' "${n:-0}"
    sleep 0.05
  done >"$TMPROOT/workers.log"
) &
sampler=$!
for i in $(seq 1 40); do
  bash "$SCRIPTS_DIR/resize-sidebars.sh" >/dev/null 2>&1
done
wait "$sampler"
workers=$(sort -n "$TMPROOT/workers.log" | tail -1)

if (( workers == 1 )); then
  ok "40 resize events were served by exactly 1 drain worker"
elif (( workers == 0 )); then
  fail "no drain worker ever ran — the dispatcher never spawned one"
else
  fail "expected at most 1 drain worker, observed $workers concurrently"
fi
sleep 1

# --- 7. the resize debounce is trailing, not periodic -------------------------
# A drag emits events continuously. Each resize pass scans every pane on the
# server, so passes taken mid-drag are wasted work superseded moments later.

printf 'client-resized debounce is trailing\n'
start_server "" default
tmux_test set-environment -g WORK_BIN /bin/true
tmux_test set-environment -g TMUXR_SIDEBAR_WIDTH 40

# Sustain events for well over a debounce window, the way a drag does.
burst_end=$((SECONDS + 2))
while (( SECONDS < burst_end )); do
  bash "$SCRIPTS_DIR/resize-sidebars.sh" >/dev/null 2>&1
  sleep 0.05
done
sleep 1

# Each pass runs one server-wide `list-panes -a`, which the server logs.
passes=$(tmux_test show-messages 2>/dev/null | grep -c 'list-panes -a')
passes=${passes:-0}
if (( passes >= 1 && passes <= 3 )); then
  ok "a 2s event stream produced $passes resize pass(es)"
elif (( passes == 0 )); then
  fail "no resize pass ran at all after the burst went quiet"
else
  fail "expected a trailing debounce (<=3 passes), got $passes — resizing per tick"
fi

printf '\n'
if (( FAILURES == 0 )); then
  printf 'hook tests OK\n'
else
  printf '%d hook test(s) failed\n' "$FAILURES" >&2
fi
exit $(( FAILURES > 0 ))
