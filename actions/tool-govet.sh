#!/usr/bin/env bash
eval "$GLUE_BOOTSTRAP"
bootstrap || exit

ensure.cmd 'go'

go get ./...

unbootstrap