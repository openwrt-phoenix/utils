#!/bin/sh
branch1=$1
branch2=$2
git reset --hard
git checkout ${branch1}
commits=`git log --pretty=%H --invert-grep --grep Squashed --no-merges | tac | xargs`
git checkout ${branch2}
for commit in ${commits}
do
    clear
    git show ${commit}
    echo -n cherry-pick?
    read -e opt
    [ "${opt}" == "y" ] || continue
    git cherry-pick ${commit} || /bin/bash
done

