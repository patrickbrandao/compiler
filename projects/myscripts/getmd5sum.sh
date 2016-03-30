#!/bin/sh

file=$1

if [ -f "$file" ]; then
	md5sum $file 2>/dev/null | awk '{print $1}'
else
	echo ""
fi

