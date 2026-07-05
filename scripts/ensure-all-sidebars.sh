#!/usr/bin/env bash
# Create sidebar panes in tracked session windows (when sidebar is visible).

set -euo pipefail

SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

bash "$SCRIPTS_DIR/repair-all-sidebars.sh" 2>/dev/null || true
