# tmux-tmuxr

TPM plugin for [workctl](../workctl). Sets tmux hooks, keybindings, and status
line integration; starts `workctld` and manages sidebar panes.

## Requirements

- tmux 3.x (3.5+ for `pane-title-changed` hook)
- Built [workctl](../workctl) checkout as a sibling directory (`../workctl/dist/`)

## Install

### Local development (chezmoi)

This repo is loaded from `~/.tmux.conf` via:

```tmux
run "bash ~/dev/projects/tmuxr/tmux-tmuxr/tmux-tmuxr.tmux"
```

Build workctl first:

```bash
cd ~/dev/projects/tmuxr/workctl && npm run build
```

Reload tmux: `prefix + r`

### TPM (when published)

```tmux
set -g @plugin "github-user/tmux-tmuxr"
```

## Keybindings

| Binding            | Action                                    |
| ------------------ | ----------------------------------------- |
| `prefix + Shift+S` | Track current session and scan for agents |
| `prefix + Shift+W` | Toggle sidebar pane in current window     |

## Hooks

Reactive hooks (all `run-shell -b`, append with `-ga`):

- `after-split-window` / `after-new-window` — scan for agents
- `pane-exited` — mark agent detached
- `session-closed` — archive workspace
- `pane-title-changed` — feed title changes (tmux 3.5+)
- `client-attached` — reconcile after restore

## Status line

workctl agent counts are prepended to `status-right` via
`scripts/append-status.sh` (configured in chezmoi `dot_tmux.conf.tmpl`).

## Related

- CLI repo: [workctl](../workctl)
- Meta-project: `~/dev/projects/tmuxr/`
