#!/bin/bash
# Spawns wap agent roles as Remote Control sessions in detached tmux (tmux name wap-<role>) and prints their URLs.
#   notes/agents/start.sh                         the services, the lead and the stage owners (skips ones already running)
#   notes/agents/start.sh <role>                  one of the SERVICES
#   notes/agents/start.sh owner <stage>           the owner of one stage of OWNERS (wap-owner.md "Owners")
#   notes/agents/start.sh worker <branch> "<task>"   a feature worker on that branch
# The prompt of a role is notes/agents/<role>.md, read from origin/main by the session itself.
REPO=/Users/me/dev/angles/wap
SPAWN="$HOME/dev/bin/claude-remote.sh"
SERVICES=(integrator interviewer fixer reviewer simplifier lead)
OWNERS=(reader binding emitter native)

supervisor_name() { echo "${WARP_SUPERVISOR:-the session that started you (see ListAgents)}"; }

prompt_for() {
	local role=$1
	echo "You are the wap $role. Read notes/agents/$role.md (the fleet rules are AGENTS.md, loaded automatically) (use \`git -C $REPO show origin/main:notes/agents/$role.md\` if the checkout is stale) and act as described there. Your Supervisor is $(supervisor_name)."
}

running() { tmux has-session -t "=wap-$1" 2>/dev/null; }

spawn() {
	local name=$1 prompt=$2
	if running "$name"; then echo "wap-$name already runs (tmux attach -t wap-$name)"; return; fi
	"$SPAWN" "$name" "$REPO" "$prompt" | grep -E "Open:|WARNING|busy"
}

case "$1" in
	"") for role in "${SERVICES[@]}"; do spawn "$role" "$(prompt_for "$role")"; done
		for stage in "${OWNERS[@]}"; do spawn "$stage" "$(prompt_for wap-owner) YOU ARE wap-$stage, the owner named so in the Owners table."; done ;;
	owner)
		[ -n "$2" ] || { echo "usage: $0 owner <stage>" >&2; exit 1; }
		spawn "$2" "$(prompt_for wap-owner) YOU ARE wap-$2, the owner named so in the Owners table." ;;
	worker)
		[ -n "$2" ] && [ -n "$3" ] || { echo "usage: $0 worker <branch> \"<task>\"" >&2; exit 1; }
		spawn "$2" "$(prompt_for worker) YOUR BRANCH: $2. YOUR TASK: $3" ;;
	*) spawn "$1" "$(prompt_for "$1")" ;;
esac
