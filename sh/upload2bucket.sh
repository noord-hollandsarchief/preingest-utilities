#!/usr/bin/env sh

if [ -n "$1" ]; then
    aws s3 cp --recursive /data/"$1"/opex s3://com.preservica.nhatest.bulk/opex
fi
