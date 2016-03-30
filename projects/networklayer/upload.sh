#!/bin/sh

ip="$1"
port="$2"
if [ "x$ip" = "x" ]; then ip=172.20.0.242; fi
if [ "x$port" = "x" ]; then port=22; fi

chmod +x *
rsync -rap -e "ssh -p $port" rc.inet1.sh root@$ip:/etc/rc.d/rc.inet1 && /bin/echo -n "." || /bin/echo -n "x"
rsync -rap -e "ssh -p $port" eth-mac-sort.sh root@$ip:/usr/sbin/eth-mac-sort && /bin/echo -n "." || /bin/echo -n "x"

