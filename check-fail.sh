#!/bin/sh
log=.build.log
text=`sed -n -e '/\*\*\* \[.*\/\(compile\|install\)\]/p' $log`
text=`echo "$text"|sed 's@.*\*\*\* \[\(.*\)\/\(compile\|install\)\].*@\1@'`
echo "$text"
[ "$1" == "l" ] && vim `echo "$text" | sed -e 's@/host$@@' -e 's@^.*$@build/logs/\0/*.txt@'`
[ "$1" == "m" ] && vim `echo "$text" | sed -e 's@/host$@@' -e 's@^.*$@openwrt/\0/Makefile@'`
