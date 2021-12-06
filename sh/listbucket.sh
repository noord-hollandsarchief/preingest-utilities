#!/usr/bin/env sh
FILE=/root/.aws/bucket
if test -f $FILE; then
	BUCKET=`cat /root/.aws/bucket`
	aws s3 ls --recursive s3://"$BUCKET"/opex
	if [[ $? -ne 0 ]]; then
		echo "Bucket is empty!"
	fi
	
else
	echo "File 'bucket' in folder '/root/.aws/' not found!"
fi

exit 0