#!/bin/sh
[ -d .git ] || cd `dirname $0`/..
exec git "$@"

