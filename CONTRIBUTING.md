# Contributing to tmux-tmuxr

Thank you for contributing. This document covers local setup, checks, and the
release process for the [tmux-tmuxr](https://github.com/aguil/tmux-tmuxr) TPM
plugin.

## Prerequisites

- tmux 3.x (3.5+ to exercise `pane-title-changed`)
- [Jujutsu](https://jj-vcs.github.io/jj/latest/) for version control in this repo
- [pre-commit](https://pre-commit.com/) for markdown formatting (optional locally)
- A built or installed [`@aguil/work`](https://github.com/aguil/work) CLI for manual testing

Optional:

- [fzf](https://github.com/junegunn/fzf) — repo picker smoke tests
- [tmux-resurrect](https://github.com/tmux-plugins/tmux-resurrect) — restore integration

## Setup

```bash
git clone https://github.com/aguil/tmux-tmuxr.git
cd tmux-tmuxr
pre-commit install   # optional
```

For development against a local `work` checkout, place it as a sibling directory
(`../work`) and build:

```bash
cd ../work && npm ci && npm run build
```

Load the plugin from your dev path in `~/.tmux.conf`:

```tmux
run "bash /path/to/tmux-tmuxr/tmux-tmuxr.tmux"
```

## Checks before opening a PR

```bash
bash scripts/check.sh
pre-commit run --all-files   # when hooks installed
```

`scripts/check.sh` runs `bash -n`, `shellcheck`, and verifies executable bits on
`tmux-tmuxr.tmux` and `scripts/*.sh`.

## Version control

This repository uses **Jujutsu** colocated with git.

- Use `jj` for all mutations. Do not run `git commit`, `git rebase`, or other
  git write commands in this checkout.
- Commit messages use **Conventional Commits** (`type: subject`) with a body
  paragraph explaining why the change was made.

## Project layout

See [AGENTS.md](./AGENTS.md) for module-level orientation aimed at coding agents.

## TPM distribution

Unlike `@aguil/work`, this plugin is distributed as a **git repository** via
[TPM](https://github.com/tmux-plugins/tpm). There is no npm package or build
artifact — users clone tagged releases into `~/.tmux/plugins/tmux-tmuxr/`.

Published tree contents:

- `tmux-tmuxr.tmux` (entry point)
- `scripts/` (hook and sidebar helpers)
- `VERSION`, `LICENSE`, `README.md`, `CHANGELOG.md`

## Releasing

Releases are automated with
[release-please](https://github.com/googleapis/release-please).

### Day to day

1. Merge PRs to `main` with **Conventional Commit** titles (`feat:`, `fix:`,
   `perf:`, etc.). The commit subject becomes the changelog bullet; the body is
   not included.
2. release-please opens or updates a **Release PR** (`chore: release X.Y.Z`)
   that bumps `VERSION`, `.release-please-manifest.json`, and `CHANGELOG.md`.
   `CHANGELOG.md` is excluded from pre-commit (release-please owns its format).
3. Review the Release PR. Merge when ready to ship.
4. Merging the Release PR creates the `vX.Y.Z` tag and GitHub Release.
5. TPM users can pin `set -g @plugin 'aguil/tmux-tmuxr#vX.Y.Z'` or run
   `prefix + U` to pull latest.

### Pre-1.0 semver

While the version is below `1.0.0`, `feat` commits bump the **patch** version
(`0.1.0` → `0.1.1`). Breaking changes (`feat!:` or `BREAKING CHANGE:` footer)
bump the **minor** version (`0.1.0` → `0.2.0`).

### Bootstrap (one time)

After the first release-please setup merges to `main`:

1. Tag **`v0.1.0`** on the commit that matches `VERSION` / published changelog
   (align with `@aguil/work@0.1.0`).
2. Create the GitHub Release from that tag if release-please did not already.
3. If a release used a component-prefixed tag (e.g. `tmux-tmuxr-v0.1.1`), add a
   matching **`v0.1.1`** tag on the same commit so TPM pins
   `#vX.Y.Z` work as documented.
4. Verify TPM install: `set -g @plugin 'aguil/tmux-tmuxr#v0.1.0'`, then
   `prefix + I`.

### Compatibility with `@aguil/work`

Document minimum `work` versions in `README.md` when plugin releases depend on
new CLI behavior. `tmux-tmuxr.tmux` enforces `MIN_WORK_VERSION` at load time.

## Reporting issues

Open issues at [github.com/aguil/tmux-tmuxr/issues](https://github.com/aguil/tmux-tmuxr/issues).
Include tmux version (`tmux -V`), plugin version (`VERSION` file or git tag),
and `work --version`.
