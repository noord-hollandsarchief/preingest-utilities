#!/usr/bin/env sh
if [[ -n "$1" -a -n "$2" -a -n "$3" ]]; then
	cd $3
    tar -cvf "$1" "$2" && rm -R "$2"
	#tar -cvf 'Provincie Noord-Holland.0000.tar' 'Provincie Noord-Holland' && rm -R 'Provincie Noord-Holland'
fi