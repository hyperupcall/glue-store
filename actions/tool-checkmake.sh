#!/usr/bin/env bash
eval "$GLUE_BOOTSTRAP"
bootstrap

action() {
	ensure.cmd 'checkmake'

	for file in **/{Makefile,GNUMakefile,*.mk}; do
		checkmake  "$file"
	done
	unset -v file
}

action "$@"
unbootstrap
