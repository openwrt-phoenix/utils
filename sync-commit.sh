#!/bin/sh
branch1=$1
branch2=$2
git reset --hard
git checkout $branch1
commits=`git log --pretty=%h --invert-grep --grep Squashed --no-merges | tac | xargs`
git checkout $branch2
git cherry-pick $commits

