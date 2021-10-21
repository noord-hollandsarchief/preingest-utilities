#!/usr/bin/env sh
if [ -n "$1" ]; then
	pwsh /etc/webhook/export-checksum.ps1 "$1"
fi