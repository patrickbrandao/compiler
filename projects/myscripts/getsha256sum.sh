#!/bin/sh

file=$1

if [ -f "$file" ]; then
	sha256sum $file 2>/dev/null | awk '{print $1}'
else
	echo ""
fi
