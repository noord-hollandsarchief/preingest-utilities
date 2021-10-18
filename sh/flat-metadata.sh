#!/usr/bin/env sh
if [ -n "$1" ]; then
	pwsh /etc/webhook/flat-metadata.ps1 $1
fi