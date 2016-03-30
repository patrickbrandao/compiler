#!/bin/sh

#
# - Executar comando silenciosamente e dar feedback
	PREPLOG=""
	preprun(){
		label="$1"
		cmd="$2"
		logit -n "$label"
		_plog=$(eval "$cmd" 2>&1)
		PREPLOG="$PREPLOG|$label::$_plog"
		echo_ok
	}
	ifexecrun(){
		label="$1"
		cmd="$2"
		params="$3"
		if [ -x "$cmd" ]; then
			logit -n "$label"
			_plog=$(eval "$cmd $params" 2>&1)
			PREPLOG="$PREPLOG|$label::$_plog"
			echo_ok
		fi
	}
