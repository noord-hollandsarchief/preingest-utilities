#!/usr/bin/env sh
if [[ -n "$1" ]]; then
	xsltproc '/etc/webhook/flatten.xsl' "$1"
fi