#!/usr/bin/env bash
eval "$GLUE_BOOTSTRAP"
bootstrap || exit

task() {
	# glue useAction(tool-shdoc.sh)
	util.get_action 'tool-shdoc.sh'
	source "$REPLY"
}

task "$@"
unbootstrap
