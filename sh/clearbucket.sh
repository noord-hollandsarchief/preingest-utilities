#!/usr/bin/env sh
FILE=/root/.aws/bucket
if test -f $FILE; then
	BUCKET=`cat /root/.aws/bucket`
	aws s3 rm --recursive s3://"${BUCKET}"/opex
else
	echo "File 'bucket' in folder '/root/.aws/' not found!"
fi

exit 0