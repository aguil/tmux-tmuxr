# tmux-tmuxr — agent instructions

Bash TPM plugin shell for [work](https://github.com/aguil/work). Sets hooks,
keybindings, and delegates to `work` / `workd` binaries.

## Layout

- `tmux-tmuxr.tmux` — plugin entry point (hooks, keybindings, daemon start)
- `scripts/` — sidebar toggle, track session, status line, daemon lifecycle
- `VERSION` — semver tracked by release-please

## Development

Plugin resolves work from `../work/dist/` relative to this directory (sibling
dev checkout). After changing work, rebuild:

```bash
cd ../work && npm run build
tmux source-file ~/.tmux.conf
```

Validate shell scripts:

```bash
bash scripts/check.sh
```

Before committing markdown: `pre-commit run --all-files` (when hooks installed).

## Version control

Jujutsu colocated with git. Use `jj` only — no `git commit` / `git rebase`.

- Dev workspace: `~/dev/projects/tmuxr/tmux-tmuxr`
- Canonical: `~/dev/repos/github.com/aguil/tmux-tmuxr`

## TPM packaging

- Entry file: `tmux-tmuxr.tmux` (TPM sources all `*.tmux` in the clone root).
- Install line: `set -g @plugin 'aguil/tmux-tmuxr'` (optional pin `#vX.Y.Z`).
- Exports `WORK_BIN`, `WORKD_BIN`, `TMUXR_SCRIPTS_DIR`, `TMUXR_VERSION`,
  `TMUXR_SIDEBAR_WIDTH`, and `TMUXR_SIDEBAR_POSITION` via `tmux set-environment`.
- TPM users get `work` from `PATH` (global `npm install -g @aguil/work`); dev
  sibling `../work/dist/` takes precedence when present.
- No build step — git tags are releases. Validate with `bash scripts/check.sh`.

## Release

[release-please](https://github.com/googleapis/release-please) opens Release PRs
on `main`; merging creates `vX.Y.Z` + GitHub Release. Config:
`.release-please-manifest.json`, `release-please-config.json` (`release-type:
simple`). First bootstrap: tag `v0.1.0` on `main` after merge. See
[CONTRIBUTING.md](./CONTRIBUTING.md#releasing).

## Conventions

- Hooks use `run-shell -b`; lifecycle hooks use `set-hook -g` (replace on plugin reload, non-blocking)
- Sidebar panes marked with `-sidebar 1`
- Uppercase `W` / `S` bindings (lowercase `w` is tmux choose-tree)
