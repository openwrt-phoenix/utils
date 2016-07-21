#!/bin/sh
#curdir=`pwd`
basedir=`dirname $0`
if [ -d .git ];then
    unset basedir
elif [ -d "$basedir/.git" ];then
    cd $basedir
elif [ -d "$basedir/../.git" ];then
    cd $basedir/..
else
    exit 1
fi
unset basedir
exec git "$@"

