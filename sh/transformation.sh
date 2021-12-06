#!/usr/bin/env sh
if [[ -n "$1" && -n "$2" ]]; then
	java -jar /usr/src/Saxon-HE/Saxon-HE.jar -s:"$2" -xsl:"$1"
else
	echo "One of the parameters is empty!"
fi

exit 0