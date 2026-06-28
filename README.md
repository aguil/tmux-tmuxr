# tmux-tmuxr

TPM plugin for [work](../work). Sets tmux hooks, keybindings, and status
line integration; starts `workd` and manages sidebar panes.

## Requirements

- tmux 3.x (3.5+ for `pane-title-changed` hook)
- Built [work](../work) checkout as a sibling directory (`../work/dist/`)
- `fzf` (for the optional new-window repo picker)

## Install

### Local development (chezmoi)

This repo is loaded from `~/.tmux.conf` via:

```tmux
run "bash ~/dev/projects/tmuxr/tmux-tmuxr/tmux-tmuxr.tmux"
```

Build work first:

```bash
cd ~/dev/projects/tmuxr/work && npm run build
```

Reload tmux: `prefix + r`

### TPM (when published)

```tmux
set -g @plugin "github-user/tmux-tmuxr"
```

## Keybindings

| Binding            | Action                                              |
| ------------------ | --------------------------------------------------- |
| `prefix + Shift+S` | Track current session and scan for agents           |
| `prefix + Shift+W` | Toggle sidebar visibility for the whole session     |

## Hooks

Reactive hooks (background `run-shell -b` unless noted):

- `after-split-window` — scan the new pane only (`work scan --pane`)
- `after-new-window` — scan new pane, optional repo picker, ensure sidebar
- `pane-exited` — mark agent detached
- `session-closed` — archive workspace
- `pane-title-changed` — feed title changes to status adapters (tmux 3.5+)
- `client-attached` — reconcile after restore; repair dead sidebar panes
- `session-created` — opt-in auto-track (when `auto-track` config is true)

## Repo picker on new window

When configured, `prefix+c` in a tracked session opens an fzf popup to pick a
repo from `repo-scan-dir`, create a project checkout, associate a tree, and cd
the new window:

```bash
work config set repo-scan-dir ~/dev/repos[,~/other/repos]
work config set checkout-base ~/dev/projects/tmuxr   # optional
work config set prompt-repos-on-new-window true
```

Reload tmux after plugin update: `prefix + r`.

## Sidebar

Tracked sessions show a session-wide sidebar pane (toggle with `prefix + Shift+W`).
The sidebar lists agents, trees (branch, dirty, sync counts), and reconnects
after tmux-resurrect restore.

## Status line

work agent counts are prepended to `status-right` via
`scripts/append-status.sh` (configured in chezmoi `dot_tmux.conf.tmpl`).

## Related

- CLI repo: [work](../work)
- Meta-project: `~/dev/projects/tmuxr/`
