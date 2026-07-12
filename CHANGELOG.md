# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

Entries from the next release onward are updated by
[release-please](https://github.com/googleapis/release-please) when the release
PR merges. See [CONTRIBUTING.md](./CONTRIBUTING.md#releasing).

## [0.1.0] - 2026-07-12

### Added

- Initial public TPM release for [work](https://github.com/aguil/work).
- Hooks for agent scan, detach, reconcile, and optional auto-track.
- Session-wide sidebar pane with `prefix + Shift+W` toggle.
- `prefix + Shift+S` to track session and scan agents.
- `workd` daemon lifecycle on plugin load.
- tmux-resurrect integration (sidebar filter, restore reconciliation).
- Optional new-window repo picker via `work config`.
- Status-line helpers (`scripts/status.sh`, `scripts/append-status.sh`).

[0.1.0]: https://github.com/aguil/tmux-tmuxr/releases/tag/v0.1.0
