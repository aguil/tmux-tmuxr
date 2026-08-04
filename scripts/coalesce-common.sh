#!/usr/bin/env bash
# Single-flight helpers for high-frequency tmux hook dispatchers.
#
# tmux runs a hook body as a job and keeps descriptors open on the tmux *server*
# for as long as the job -- or anything still holding its stdout -- lives. High
# frequency hooks (pane-title-changed, client-resized) must therefore return
# almost immediately and hand the real work to a single detached worker.
# Otherwise a burst of events opens an unbounded number of concurrent jobs, the
# server runs out of descriptors, and tmux fails the job before the hook's shell
# ever runs (`|| true` cannot catch that). See issue #15.

tmuxr_runtime_dir() {
  local dir="${XDG_RUNTIME_DIR:-/tmp/work-$(id -u)}/work"
  mkdir -p "$dir" 2>/dev/null || true
  printf '%s\n' "$dir"
}

# How long a lock whose owner is not running may survive before another
# dispatcher reclaims it. It has to outlast the handoff from a dispatcher to the
# worker it spawns, otherwise two workers run at once.
TMUXR_LOCK_STALE_MINUTES=1

# Acquire a named single-flight lock. Prints nothing; returns 0 when acquired.
# A lock whose owner died is eventually reclaimed, so a killed worker cannot
# wedge the hook permanently.
tmuxr_lock_acquire() {
  local lock="$1"
  local owner

  if mkdir "$lock" 2>/dev/null; then
    tmuxr_lock_claim "$lock" "$$"
    return 0
  fi

  owner=$(cat "$lock/pid" 2>/dev/null || true)
  if [[ -n "$owner" ]] && kill -0 "$owner" 2>/dev/null; then
    return 1
  fi
  if [[ -z "$(find "$lock" -maxdepth 0 -mmin "+$TMUXR_LOCK_STALE_MINUTES" 2>/dev/null)" ]]; then
    return 1
  fi

  rm -rf "$lock" 2>/dev/null || true
  if mkdir "$lock" 2>/dev/null; then
    tmuxr_lock_claim "$lock" "$$"
    return 0
  fi
  return 1
}

# Record the lock owner. The dispatcher hands ownership to the worker it spawns,
# and the worker re-claims on startup, so liveness checks never track a process
# that has already exited.
tmuxr_lock_claim() {
  printf '%s\n' "${2:-$$}" >"$1/pid" 2>/dev/null || true
}

tmuxr_lock_release() {
  rm -rf "$1" 2>/dev/null || true
}

# Run "$@" fully detached from the tmux job: no shared descriptors (so tmux can
# close the job as soon as the dispatcher exits) and no SIGHUP on parent exit.
# Sets TMUXR_SPAWNED_PID to the worker's pid.
tmuxr_spawn_detached() {
  nohup "$@" </dev/null >/dev/null 2>&1 &
  # shellcheck disable=SC2034  # read by sourcing dispatchers
  TMUXR_SPAWNED_PID=$!
}
