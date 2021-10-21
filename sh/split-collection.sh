#!/usr/bin/env sh
if [ -n "$1" -a -n "$2" ]; then
	pwsh /etc/webhook/split-collection.ps1 "$1" "$2"
fi