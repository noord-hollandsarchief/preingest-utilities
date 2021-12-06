#!/usr/bin/env sh
FILE=/root/.aws/bucket
if test -f $FILE; then
	BUCKET=`cat /root/.aws/bucket`	
	if [[ -n "$1" ]]; then
		aws s3 cp --recursive /data/"$1"/opex s3://"$BUCKET"/opex
	else
		echo "Missing first input parameter from URL!"
	fi
else
	echo "File 'bucket' in folder '/root/.aws/' not found!"
	
fi

exit 0
