#!/usr/bin/env sh
if [[ -n "$1" ]]; then
	sha256sum "$1"
fi