# tmux-tmuxr

TPM plugin inspired by [herdr](https://herdr.dev) for tmux-native agent
workspaces. Companion to [work](https://github.com/aguil/work) — sets tmux
hooks, keybindings, and status-line integration; starts `workd` and manages
sidebar panes.

## Requirements

| Component                                  | Required          | Notes                                               |
| ------------------------------------------ | ----------------- | --------------------------------------------------- |
| tmux 3.x                                   | Yes               | 3.5+ for `pane-title-changed` hook                  |
| `@aguil/work`                              | Yes               | `work` and `workd` on `PATH` (`npm install -g`)     |
| [TPM](https://github.com/tmux-plugins/tpm) | Yes (TPM install) | Or direct `run` for local dev                       |
| fzf                                        | Optional          | New-window repo picker                              |
| tmux-resurrect                             | Optional          | Sidebar survives session restore (hooks configured) |

**Compatibility:** tmux-tmuxr `0.1.x` requires `@aguil/work` **≥ 0.1.0**.

## Install

### 1. Install the CLI

```bash
npm install -g @aguil/work
```

### 2. Install TPM (if needed)

```bash
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```

### 3. Add to `~/.tmux.conf`

```tmux
# List TPM plugins
set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'aguil/tmux-tmuxr'

# Pin a release (optional; omit for latest main):
# set -g @plugin 'aguil/tmux-tmuxr#v0.1.0'

# Initialize TPM — keep this line at the very bottom of ~/.tmux.conf
run '~/.tmux/plugins/tpm/tpm'
```

### 4. Install and reload

Inside tmux:

- `prefix + I` — TPM installs the plugin
- `prefix + r` — reload config (starts `workd`, sets hooks)

The plugin resolves `work` from your `PATH` when no local dev build is
present.

### Upgrade and uninstall

| Action | Keys / steps                                     |
| ------ | ------------------------------------------------ |
| Update | `prefix + U` (TPM update all), then `prefix + r` |
| Remove | Delete the `@plugin` line, then `prefix + alt+u` |

## Local development

Load this checkout directly (bypasses TPM clone):

```tmux
run "bash ~/dev/projects/tmuxr/tmux-tmuxr/tmux-tmuxr.tmux"
```

Build [work](https://github.com/aguil/work) first so the plugin picks up the
sibling dev build (`../work/dist/`):

```bash
cd ~/dev/projects/tmuxr/work && npm run build
tmux source-file ~/.tmux.conf
```

## Keybindings

| Binding            | Action                                          |
| ------------------ | ----------------------------------------------- |
| `prefix + Shift+S` | Track current session and scan for agents       |
| `prefix + Shift+W` | Toggle sidebar visibility for the whole session |

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

When configured, creating a new window in a tracked session opens an fzf popup
to pick a repo from `repo-scan-dir`, create a project checkout, associate a
tree, and cd the new window:

```bash
work config set repo-scan-dir ~/dev/repos[,~/other/repos]
work config set checkout-base ~/dev/projects   # optional
work config set prompt-repos-on-new-window true
```

Requires `fzf`. Reload tmux after plugin update: `prefix + r`.

## Sidebar

Tracked sessions show a session-wide sidebar pane (toggle with
`prefix + Shift+W`). The sidebar lists agents, trees (branch, dirty, sync
counts), and reconnects after [tmux-resurrect](https://github.com/tmux-plugins/tmux-resurrect)
restore when that plugin is installed.

## Status line

Agent counts can be prepended to `status-right`. After TPM install, the plugin
lives under `~/.tmux/plugins/tmux-tmuxr/`:

```tmux
run-shell "bash ~/.tmux/plugins/tmux-tmuxr/scripts/append-status.sh"
```

Or call `append-status.sh` from a chezmoi-managed `~/.tmux.conf` after other
theme plugins load (idempotent).

## tmux-resurrect

When [tmux-resurrect](https://github.com/tmux-plugins/tmux-resurrect) is
installed, this plugin registers hooks to:

- Strip sidebar panes from resurrect save data
- Suppress repo-picker prompts during restore
- Repair sidebars and reconcile agents after restore completes

No extra configuration is required beyond having both plugins in your TPM list.

## Daemon

On load the plugin starts `workd` if not already running. Logs and PID file:

- `${XDG_RUNTIME_DIR:-/tmp/work-$(id -u)}/work/workd.log`
- `${XDG_RUNTIME_DIR:-/tmp/work-$(id -u)}/work/workd.pid`

## Related

- CLI: [work](https://github.com/aguil/work) (`npm install -g @aguil/work`)
- Contributing: [CONTRIBUTING.md](./CONTRIBUTING.md)
