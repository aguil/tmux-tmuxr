#!/usr/bin/env bash
# Shared helpers for tmux hook scripts.

# Resolve a session name from a tmux hook_session id (#{hook_session}).
hook_session_name_from_id() {
  local session_id="${1:-}"
  if [[ -z "$session_id" ]]; then
    return 1
  fi
  tmux display-message -p -t "\$${session_id}" '#{session_name}' 2>/dev/null || true
}
