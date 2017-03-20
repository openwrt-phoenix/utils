#!/bin/sh
bb=$1
mm=master
git checkout $mm >/dev/null 2>&1
git log --pretty=%H >.commitlist-m
git checkout $bb >/dev/null 2>&1
git log --pretty=%H >.commitlist-b
cc=`diff -NrU1 .commitlist-m .commitlist-b | grep -v '^[+@-]' | tail -n 1 | xargs echo -n`
if [ -z "$cc" ]; then
    cc=`diff -NrU1 .commitlist-m .commitlist-b`
    if [ -z "$cc" ];then
        cc=`git log --pretty=%H HEAD~1.. | xargs echo -n`
        echo -n $cc
    fi
else
    echo  -n $cc
fi
rm -f .commitlist-m .commitlist-b
