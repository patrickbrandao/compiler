#!/bin/sh

dir="$1"

cd "$dir" || exit

clear
find . | sed 's#^\./#/#g' | \
	while read x; do
		if [ -f "$dir/$x" ]; then
			echo $x
		fi
	done

