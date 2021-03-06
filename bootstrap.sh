# shellcheck shell=bash

# The following is eval'ed as 'eval "$GLUE_BOOTSTRAP"'
# in either '{tasks,actions}/{,auto/}*'

# Check if  we have already bootstraped. This is useful for multiple sources of files
if [ ! "$GLUE_BOOTSTRAP_DID" = yes ]; then
	GLUE_BOOTSTRAP_DID=yes

	if [ -z "$GLUE_WD" ]; then
		echo "Context: '$0'" >&2
		echo "Context \${BASH_SOURCE[*]}: ${BASH_SOURCE[*]}" >&2
		echo "Bootstrap Error: \$GLUE_WD is empty. Exiting" >&2
		exit 1
	fi

	if [ -f "$GLUE_WD/.glue/util/bootstrap.sh" ]; then
		source "$GLUE_WD/.glue/util/bootstrap.sh"
	elif [ -f "$GLUE_WD/.glue/util/auto/bootstrap.sh" ]; then
		source "$GLUE_WD/.glue/util/auto/bootstrap.sh"
	else
		echo "Context \$0: '$0'" >&2
		echo "Context \${BASH_SOURCE[*]}: ${BASH_SOURCE[*]}" >&2
		echo "Bootstrap Error: Secondary stage bootstrap file not found. Exiting" >&2
		exit 1
	fi
fi
