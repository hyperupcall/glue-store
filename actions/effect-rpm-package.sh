#!/usr/bin/env bash
eval "$GLUE_BOOTSTRAP"
bootstrap

action() {
	# wget https://github.com/eankeen/bash-args/archive/refs/tags/v0.5.0.tar.gz
	# mv v0.5.0.tar.gz bash-args_0.5.0.orig.tar.gz
	# tar xf bash-args_0.5.0.orig.tar.gz

	fedpkg --release f34 local
}

action "$@"
unbootstrap
