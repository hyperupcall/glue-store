#!/usr/bin/env bash

# @description Print the currently running action
# @noargs
# @see task.log
action.log() {
	# ${BASH_SOURCE[0]}: Ex. ~/.../.glue/actions/auto/util/action.sh
	# ${BASH_SOURCE[1]}: Ex. ~/.../.glue/actions/auto/util/bootstrap.sh
	# ${BASH_SOURCE[2]}: Ex. ~/.../.glue/actions/auto/do-tool-prettier-init.sh

	# Path to the currently actually executing 'action' script
	# This works on the assumption that 'source's are all absolute paths
	local currentAction="${BASH_SOURCE[2]}"
	local currentActionDirname="${currentAction%/*}"

	if [ "${currentActionDirname##*/}" = auto ]; then
		if [[ "${LANG,,?}" == *utf?(-)8 ]]; then
			echo "■■■■ 🢂  START ACTION: 'auto/${currentAction##*/}'"
		else
			echo ":::: => START ACTION: 'auto/${currentAction##*/}'"
		fi
	else
		if [[ "${LANG,,?}" == *utf?(-)8 ]]; then
			echo "■■■■ 🢂  START ACTION: '${currentAction##*/}'"
		else
			echo ":::: => START ACTION: '${currentAction##*/}'"
		fi

	fi
}