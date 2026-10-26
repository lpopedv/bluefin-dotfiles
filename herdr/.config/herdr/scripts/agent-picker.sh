#!/usr/bin/env bash
# Popup picker over the agent list: j/k move, enter/l focus, q/esc close.

set -euo pipefail

workspaces=$(herdr workspace list | jq -c '[.result.workspaces[] | {key: .workspace_id, value: .label}] | from_entries')

pick=$(herdr agent list | jq -r --argjson ws "$workspaces" '
  .result.agents[]
  | [.pane_id, .agent_status, ($ws[.workspace_id] // .workspace_id), .agent, .terminal_title_stripped]
  | @tsv' |
  column -t -s $'\t' |
  fzf --no-input --reverse --no-info --with-nth=2.. \
      --bind 'j:down,k:up,l:accept,q:abort' \
      --prompt '' --header 'agents' ) || exit 0

herdr agent focus "${pick%% *}" >/dev/null
