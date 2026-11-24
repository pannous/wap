#!/bin/bash
# Rolling restart of the wap fleet: each session, once idle, saves its state on its card; then its tmux session is
# renamed wap-<name>-old-<HHMM> (kept: transcript and screen stay), its Claude exits, and a fresh one starts with
# start.sh under the same name. Sessions given as <session>=retire only save and exit.
# Usage: notes/agents/restart.sh <session>[=<start.sh arguments>|=retire]...
#   notes/agents/restart.sh wap-lead=lead wap-reader="owner reader" wap-host-port-gpu=retire
START="$(dirname "$0")/start.sh"
SAVE_PROMPT='The fleet is restarted with fresh sessions now (user order). At a safe point (your background jobs finished, or stopped when a rerun is cheap): commit and push your WIP, put your state on your card with todo note (branch, tip, next step); if this message says RETIRE, also todo release your card with that note. Then stop and answer only with the word RESTART followed by -OK.'
DONE_TEXT='RESTART-OK'
EXIT_DIALOG='will stop when you exit' # Claude's "Background work is running" question
STAMP=$(date +%H%M)
export WARP_SUPERVISOR=wap-supervisor FORCE_SPAWN=1 # spawns come one at a time as sessions go idle

SPECS=("$@")
plan_of() { local spec; for spec in "${SPECS[@]}"; do [ "${spec%%=*}" = "$1" ] && echo "${spec#*=}"; done; }
retiring=(); others=()
for spec in "${SPECS[@]}"; do
	if [ "${spec#*=}" = retire ]; then retiring+=("${spec%%=*}"); else others+=("${spec%%=*}"); fi
done

restart_one() {
	local session=$1 args; args=$(plan_of "$1")
	local old_pane="=$session-old-$STAMP:"
	tmux rename-session -t "=$session" "$session-old-$STAMP"
	tmux set-option -w -t "$old_pane" remain-on-exit on # the screen stays after Claude exits
	tmux send-keys -t "$old_pane" -l "/exit"; sleep 0.5; tmux send-keys -t "$old_pane" Enter
	sleep 3
	if tmux capture-pane -p -t "$old_pane" | grep -qF "$EXIT_DIALOG"; then # a live old session keeps its address
		tmux send-keys -t "$old_pane" 3; sleep 0.3; tmux send-keys -t "$old_pane" Enter # Stay
		tmux rename-session -t "=$session-old-$STAMP" "$session"
		echo "$(date +%T) $session kept: background work still runs; restart it later"; return
	fi
	[ "$args" = retire ] && { echo "$(date +%T) $session retired"; return; }
	eval "\"$START\" $args" | sed "s/^/$(date +%T) $session: /"
}

save_all() { # retiring sessions get RETIRE in their prompt
	[ ${#retiring[@]} -gt 0 ] && ~/dev/bin/rename-when-idle --send "RETIRE. $SAVE_PROMPT" --done "$DONE_TEXT" "${retiring[@]}" &
	[ ${#others[@]} -gt 0 ] && ~/dev/bin/rename-when-idle --send "$SAVE_PROMPT" --done "$DONE_TEXT" "${others[@]}" &
	wait
}

save_all | while read -r time session status _; do
	[ "$status" = done: ] || { echo "$time $session $status"; continue; } # "gave up on: …"
	echo "$time $session saved"
	restart_one "$session"
done
