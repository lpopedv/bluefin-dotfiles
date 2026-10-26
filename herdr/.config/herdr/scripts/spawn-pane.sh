#!/usr/bin/env bash
# Splits the active pane to the right and runs a command in the new pane.

set -euo pipefail
# Log goes to RAM: it records every pane's cwd.
exec >> "${XDG_RUNTIME_DIR:-/tmp}/herdr-spawn-pane.log" 2>&1
echo "--- $(date -Iseconds) args=$* pane=${HERDR_ACTIVE_PANE_ID:-unset} cwd=${HERDR_ACTIVE_PANE_CWD:-unset} ---"

pane="${HERDR_ACTIVE_PANE_ID:?HERDR_ACTIVE_PANE_ID not set}"

json() { python3 -c "import sys,json;d=json.load(sys.stdin);print(d$1)"; }

new_pane=$(herdr pane split "$pane" --direction right --ratio 0.5 --focus | json "['result']['pane']['pane_id']")
herdr pane run "$new_pane" "$1"
