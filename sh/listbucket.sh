#!/usr/bin/env sh
aws s3 ls --recursive s3://com.preservica.nhatest.bulk/opex

if [ $? -ne 0 ]; then
    echo ""
fi