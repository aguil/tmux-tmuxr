# tmux-tmuxr

TPM plugin inspired by [herdr](https://herdr.dev) for tmux-native agent
workspaces. Companion to [work](https://github.com/aguil/work) — sets tmux
hooks and keybindings; starts `workd` and manages sidebar panes.

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

Reactive hooks, dispatched with `if-shell -b <command> ''` so a handler that
fails is never printed into a pane:

- `after-split-window` — scan the new pane only (`work scan --pane`)
- `after-new-window` — scan new pane, optional repo picker, ensure sidebar
- `pane-exited` — mark agent detached
- `session-closed` — archive workspace
- `pane-title-changed` — feed title changes to status adapters (tmux 3.5+)
- `client-attached` — reconcile after restore; repair dead sidebar panes
- `client-resized` — restore sidebar widths after a display change
- `session-created` — opt-in auto-track (when `auto-track` config is true)

`pane-title-changed` and `client-resized` fire in bursts, so their hooks only
record the event and return; a single detached worker coalesces the burst and
runs `work` serially. Nothing spawns a `work` process per event.

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

`scripts/status.sh` prints agent counts as a short string. The plugin does not
write status-line options — whatever owns your status line owns those — so add
it to your config yourself. After TPM install the plugin lives under
`~/.tmux/plugins/tmux-tmuxr/`.

**If nothing else owns `status-right`** (no theme plugin, or one you have
already told not to set it), assign it directly:

```tmux
set -g status-right '#(bash ~/.tmux/plugins/tmux-tmuxr/scripts/status.sh) '
```

**If a theme owns `status-right`, do not use the line above** — `set -g`
replaces the whole option, so the theme's own segments disappear. Use the
theme's segment mechanism instead. [tmux-powerkit](https://github.com/fabioluciano/tmux-tokyo-night)
takes an inline external segment with a TTL, so the script runs once per
interval rather than on every redraw:

```tmux
set -g @powerkit_plugins "external(\"󰚩\"|\"#(bash ~/.tmux/plugins/tmux-tmuxr/scripts/status.sh)\"|\"secondary\"|\"active\"|\"5\"),datetime"
```

Themes with no segment mechanism at all — `janoamaral/tokyo-night-tmux`, for
one — leave no composition-safe option: `status-right` is a single global with
no merge protocol, which is why this plugin stopped writing it. Appending to
whatever the theme set is possible from your own config, but it re-prepends on
every `source-file` unless you guard it. Prefer a theme that exposes segments.

> **Changed in 0.2.0 — action required.** Earlier versions injected this segment
> automatically via `scripts/append-status.sh` and rewrote `window-status-format`
> from a hardcoded Tokyo Night palette. Both scripts are gone: they only worked
> against one theme and silently rendered nothing against themes that build
> `status-format[0]`.
>
> **Remove this line from your `~/.tmux.conf` before reloading** — earlier
> versions of this README told you to add it, and it now points at a deleted
> script, so tmux reports an error on every `source-file`:
>
> ```tmux
> run-shell "bash ~/.tmux/plugins/tmux-tmuxr/scripts/append-status.sh"
> ```
>
> The segment no longer appears until you add one of the lines above.
>
> On first load after upgrading, a one-time cleanup strips the `#()` calls those
> versions injected into `status-right` and the window formats. It does **not**
> undo the wholesale rewrite of `window-status-format` /
> `window-status-current-format`, which those versions replaced with hardcoded
> Tokyo Night strings — that content is theme-owned, and your theme reasserts it
> the next time it loads. If your window tabs look wrong after upgrading, reload
> your theme; the cleanup runs once and will not retry.

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
