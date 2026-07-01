# tmux-tmuxr — agent instructions

Bash TPM plugin shell for [work](../work). Sets hooks, keybindings, and
delegates to `work` / `workd` binaries.

## Layout

- `tmux-tmuxr.tmux` — plugin entry point (hooks, keybindings, daemon start)
- `scripts/` — sidebar toggle, track session, status line, daemon lifecycle

## Development

Plugin resolves work from `../work/dist/` relative to this directory.
After changing work, rebuild:

```bash
cd ../work && npm run build
tmux source-file ~/.tmux.conf
```

Validate shell scripts:

```bash
for s in scripts/*.sh; do bash -n "$s"; done
bash -n tmux-tmuxr.tmux
```

Before committing markdown: `pre-commit run --all-files` (when hooks installed).

## Version control

Jujutsu colocated with git. Use `jj` only — no `git commit` / `git rebase`.

- Dev workspace: `~/dev/projects/tmuxr/tmux-tmuxr`
- Canonical: `~/dev/repos/github.com/aguil/tmux-tmuxr`

## Conventions

- Hooks use `run-shell -b`; lifecycle hooks use `set-hook -g` (replace on plugin reload, non-blocking)
- Sidebar panes marked with `-sidebar 1`
- Uppercase `W` / `S` bindings (lowercase `w` is tmux choose-tree)
