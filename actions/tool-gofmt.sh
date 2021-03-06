#!/usr/bin/env bash
eval "$GLUE_BOOTSTRAP"
bootstrap

action() {
	ensure.cmd 'gofmt'

	go list -f '{{.Dir}}' ./... \
		| xargs gofmt -s -l -w
}

action "$@"
unbootstrap
