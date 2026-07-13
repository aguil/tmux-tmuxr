# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

Entries from the next release onward are updated by
[release-please](https://github.com/googleapis/release-please) when the release
PR merges. See [CONTRIBUTING.md](./CONTRIBUTING.md#releasing).

## [0.1.2](https://github.com/aguil/tmux-tmuxr/compare/v0.1.1...v0.1.2) (2026-07-13)


### Added

* add fzf popup helper and new-window repo picker scripts ([d85f033](https://github.com/aguil/tmux-tmuxr/commit/d85f033bda36953c8356798754ff949ee68c72b1))
* add session and sidebar scripts ([03cb864](https://github.com/aguil/tmux-tmuxr/commit/03cb86426d83494ca938cef0a4a815d249bf014e))
* add TPM plugin entry and hooks ([71f69e4](https://github.com/aguil/tmux-tmuxr/commit/71f69e400d2da9bef6ab56dffb3d97b4045a75cd))
* expose plugin version and guard minimum work CLI ([b510900](https://github.com/aguil/tmux-tmuxr/commit/b51090006ca829a964dda727a30b7f18832498ca))
* opt-in auto-track on session creation with scan ([80df0d3](https://github.com/aguil/tmux-tmuxr/commit/80df0d35b353a900246e2ebcd5380cc5ce1c0f4f))
* pass tmux session name to work status script ([2fff5c5](https://github.com/aguil/tmux-tmuxr/commit/2fff5c56adb3909e9455228396db826fa322b4b5))
* session-wide sidebar, hooks, and attach repair ([ba0d52e](https://github.com/aguil/tmux-tmuxr/commit/ba0d52e0245e1a88611d748dee3713f378c50d12))
* TPM plugin, hooks, and sidebar integration ([61653c2](https://github.com/aguil/tmux-tmuxr/commit/61653c20036654df8bf13bae3cff79f190f2a34f))
* use scan --pane in tmux hooks ([7ec527e](https://github.com/aguil/tmux-tmuxr/commit/7ec527e3815b2c493d2d33283286e99376065b5e))


### Fixed

* **ci:** satisfy shellcheck in scripts/check.sh ([4e51f54](https://github.com/aguil/tmux-tmuxr/commit/4e51f540d3586922299fd1f7a5ae002da5e26e28))
* continue after-new-window when repo picker fails ([e36606a](https://github.com/aguil/tmux-tmuxr/commit/e36606a11aeb2e3e57c68174f4671b02268f0a58))
* exclude work sidebars from resurrect saves ([0c46e78](https://github.com/aguil/tmux-tmuxr/commit/0c46e78d4b17290129bef8e3d7e68681a3477db1))
* guard repo picker during restore and resolve work binaries ([ea20dc7](https://github.com/aguil/tmux-tmuxr/commit/ea20dc7fac932cdf5d5a5bb910d585b9c17bb0d8))
* hydrate tracked session before sidebar repair ([4eb7c0f](https://github.com/aguil/tmux-tmuxr/commit/4eb7c0fa456ffff2ea637e575d85fc810ba7f7c9))
* keep agent counts off window tabs ([340892d](https://github.com/aguil/tmux-tmuxr/commit/340892d4c9b1b611bd8ccb6da31efc9cf85c1b0a))
* make sidebar toggle behavior non-disruptive ([8c343f8](https://github.com/aguil/tmux-tmuxr/commit/8c343f80fbfcc77ba4c0c224b8fa529975ca4f40))
* pass safe hook session ids instead of names ([a37fed5](https://github.com/aguil/tmux-tmuxr/commit/a37fed53728c282f9a0573aad4be4a2d56e05687))
* quote split-window args in ensure-sidebar ([f6f382a](https://github.com/aguil/tmux-tmuxr/commit/f6f382addd93092000e6517814fc815e8f2e6d95))
* recreate sidebars after tmux-resurrect restore ([e6addfc](https://github.com/aguil/tmux-tmuxr/commit/e6addfcb6ba5a034d20728404ad821cb90bf4269))
* **release:** use vX.Y.Z tags without component prefix ([36802bd](https://github.com/aguil/tmux-tmuxr/commit/36802bdba16fee3460ec7e865ed300078ff37531))
* **release:** use vX.Y.Z tags without component prefix ([a26e8c6](https://github.com/aguil/tmux-tmuxr/commit/a26e8c65136f872243ab8f261ab7fb97914472ee))
* repair sidebars after resurrect restore ([96e981f](https://github.com/aguil/tmux-tmuxr/commit/96e981fbf1de2c999fd03f88863aef283c189e55))
* replace tmux hooks on plugin reload instead of appending ([80dbcbd](https://github.com/aguil/tmux-tmuxr/commit/80dbcbd96e4b30f0698805a5b1a7909aa72203d3))
* retry sidebar repair on client attach ([360d47b](https://github.com/aguil/tmux-tmuxr/commit/360d47b7f1090959e1377fc9e2460c233e061dd3))
* run after-new-window hook in background ([6347c3f](https://github.com/aguil/tmux-tmuxr/commit/6347c3fdb7f84f68cc5f5a608b5a230562cacc54))
* **sidebar:** refresh config cache before resize ([2d0187b](https://github.com/aguil/tmux-tmuxr/commit/2d0187bbc2b44d681963854aa9a31102ca804bb3))
* **sidebar:** resize handling and faster show ([a5e0494](https://github.com/aguil/tmux-tmuxr/commit/a5e049403954ded57d57bcca4cfb6dd43503737c))
* **sidebar:** restore configured width after client resize ([e03e9d8](https://github.com/aguil/tmux-tmuxr/commit/e03e9d8dcdefe41d71432dabae92620ebeaf180b))
* track session inline when auto-track races repo picker ([c3bd863](https://github.com/aguil/tmux-tmuxr/commit/c3bd863d7e2eac3832727a43c093fef92920a1ee))

## [0.1.1](https://github.com/aguil/tmux-tmuxr/compare/tmux-tmuxr-v0.1.0...tmux-tmuxr-v0.1.1) (2026-07-12)


### Added

* add fzf popup helper and new-window repo picker scripts ([d85f033](https://github.com/aguil/tmux-tmuxr/commit/d85f033bda36953c8356798754ff949ee68c72b1))
* add session and sidebar scripts ([03cb864](https://github.com/aguil/tmux-tmuxr/commit/03cb86426d83494ca938cef0a4a815d249bf014e))
* add TPM plugin entry and hooks ([71f69e4](https://github.com/aguil/tmux-tmuxr/commit/71f69e400d2da9bef6ab56dffb3d97b4045a75cd))
* expose plugin version and guard minimum work CLI ([b510900](https://github.com/aguil/tmux-tmuxr/commit/b51090006ca829a964dda727a30b7f18832498ca))
* opt-in auto-track on session creation with scan ([80df0d3](https://github.com/aguil/tmux-tmuxr/commit/80df0d35b353a900246e2ebcd5380cc5ce1c0f4f))
* pass tmux session name to work status script ([2fff5c5](https://github.com/aguil/tmux-tmuxr/commit/2fff5c56adb3909e9455228396db826fa322b4b5))
* session-wide sidebar, hooks, and attach repair ([ba0d52e](https://github.com/aguil/tmux-tmuxr/commit/ba0d52e0245e1a88611d748dee3713f378c50d12))
* TPM plugin, hooks, and sidebar integration ([61653c2](https://github.com/aguil/tmux-tmuxr/commit/61653c20036654df8bf13bae3cff79f190f2a34f))
* use scan --pane in tmux hooks ([7ec527e](https://github.com/aguil/tmux-tmuxr/commit/7ec527e3815b2c493d2d33283286e99376065b5e))


### Fixed

* **ci:** satisfy shellcheck in scripts/check.sh ([4e51f54](https://github.com/aguil/tmux-tmuxr/commit/4e51f540d3586922299fd1f7a5ae002da5e26e28))
* continue after-new-window when repo picker fails ([e36606a](https://github.com/aguil/tmux-tmuxr/commit/e36606a11aeb2e3e57c68174f4671b02268f0a58))
* exclude work sidebars from resurrect saves ([0c46e78](https://github.com/aguil/tmux-tmuxr/commit/0c46e78d4b17290129bef8e3d7e68681a3477db1))
* guard repo picker during restore and resolve work binaries ([ea20dc7](https://github.com/aguil/tmux-tmuxr/commit/ea20dc7fac932cdf5d5a5bb910d585b9c17bb0d8))
* hydrate tracked session before sidebar repair ([4eb7c0f](https://github.com/aguil/tmux-tmuxr/commit/4eb7c0fa456ffff2ea637e575d85fc810ba7f7c9))
* keep agent counts off window tabs ([340892d](https://github.com/aguil/tmux-tmuxr/commit/340892d4c9b1b611bd8ccb6da31efc9cf85c1b0a))
* make sidebar toggle behavior non-disruptive ([8c343f8](https://github.com/aguil/tmux-tmuxr/commit/8c343f80fbfcc77ba4c0c224b8fa529975ca4f40))
* pass safe hook session ids instead of names ([a37fed5](https://github.com/aguil/tmux-tmuxr/commit/a37fed53728c282f9a0573aad4be4a2d56e05687))
* quote split-window args in ensure-sidebar ([f6f382a](https://github.com/aguil/tmux-tmuxr/commit/f6f382addd93092000e6517814fc815e8f2e6d95))
* recreate sidebars after tmux-resurrect restore ([e6addfc](https://github.com/aguil/tmux-tmuxr/commit/e6addfcb6ba5a034d20728404ad821cb90bf4269))
* repair sidebars after resurrect restore ([96e981f](https://github.com/aguil/tmux-tmuxr/commit/96e981fbf1de2c999fd03f88863aef283c189e55))
* replace tmux hooks on plugin reload instead of appending ([80dbcbd](https://github.com/aguil/tmux-tmuxr/commit/80dbcbd96e4b30f0698805a5b1a7909aa72203d3))
* retry sidebar repair on client attach ([360d47b](https://github.com/aguil/tmux-tmuxr/commit/360d47b7f1090959e1377fc9e2460c233e061dd3))
* run after-new-window hook in background ([6347c3f](https://github.com/aguil/tmux-tmuxr/commit/6347c3fdb7f84f68cc5f5a608b5a230562cacc54))
* **sidebar:** refresh config cache before resize ([2d0187b](https://github.com/aguil/tmux-tmuxr/commit/2d0187bbc2b44d681963854aa9a31102ca804bb3))
* **sidebar:** resize handling and faster show ([a5e0494](https://github.com/aguil/tmux-tmuxr/commit/a5e049403954ded57d57bcca4cfb6dd43503737c))
* **sidebar:** restore configured width after client resize ([e03e9d8](https://github.com/aguil/tmux-tmuxr/commit/e03e9d8dcdefe41d71432dabae92620ebeaf180b))
* track session inline when auto-track races repo picker ([c3bd863](https://github.com/aguil/tmux-tmuxr/commit/c3bd863d7e2eac3832727a43c093fef92920a1ee))

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
