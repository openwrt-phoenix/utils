#!/bin/sh

# define
#------------------------------------------------------

export LANG=en_US.UTF-8
export EDITOR=:

curdir=`pwd`
basedir=`dirname $0`
basedir=`(cd $basedir; pwd)`
unset SSH_ASKPASS

# function
#------------------------------------------------------
initremote()
{
    local remote=$1 url=$2

    if git remote | grep -q "^$remote$"; then
        if [ -n "$R" ]; then
            callgit remote remove $remote
            callgit remote add $remote $url
        else
            callgit remote set-url $remote $url
        fi
    else
        callgit remote add $remote $url
    fi
}

callgit()
{
    local opt= q= o=$1
    [ "$o" == "subtree" ] && o=$2
    case "$o" in
        merge) q=$Q;;
        pull) q=$Q;;
        *);;
    esac
    while [ -n "$1" ]
    do
        opt="$opt '$1'"
        shift
    done
    eval "echo '--> git' $opt" >&2
    if [ -n "$q" ]; then
        eval git $opt | grep '^Merge'
        return ${PIPESTATUS[0]}
    else
        eval git $opt
        return $?
    fi
}
init()
{
    [ -d "$I" -a -n "$R" ] && rm -rf "$I"
    [ -d "$I/.git" ] || rm -rf "$I"
    [ -d "$I" ] || git init "$I"
    cd "$I"
    initremote origin git@github.com:speadup/openwrt.git
    initremote origin-master $M/git.openwrt.org/openwrt.git
    initremote origin-lede $M/git.lede-project.org/source.git
    initremote origin-chaos_calmer $M/git.openwrt.org/15.05/openwrt.git
    initremote origin-barrier_breaker $M/git.openwrt.org/14.07/openwrt.git
    
    if ! git branch | grep -q master; then
        callgit fetch origin
    fi
    callgit checkout master
    callgit pull origin-master master
    callgit push -u origin master

    callgit checkout lede-master
    if git branch | grep -q lede-master; then
        callgit pull origin-lede master
    else    
        callgit fetch origin-lede
        callgit checkout origin-lede-master/master -b lede-master
    fi
    callgit push -u origin lede-master

    # init branch
    if ! git branch | grep -q chaos_calmer; then
        callgit checkout 2823965 -b chaos_calmer
    fi
    if ! git branch | grep -q barrier_breaker; then
        callgit checkout d303b27 -b barrier_breaker
    fi
}
update()
{
    update_branch chaos_calmer 45973 
    callgit push -u origin chaos_calmer 
    update_branch barrier_breaker 41863
    callgit push -u origin barrier_breaker
}
update_branch()
{
    local name=$1 rev=$2 commit=
    
    callgit fetch -n origin-$name master
    callgit checkout $name
    callgit pull origin $name
    commit=`git log -1 | grep 'git-svn-id:' | awk -F\  '{print $2}' | awk -F@ '{print $2}'`
    git branch | grep -q remote-$name && callgit branch -D remote-$name
    callgit checkout origin-$name/master -b remote-$name
    [ "$commit" == $rev ] && commit=$((rev + 1))
    commit=`git log -1 --pretty=%h --grep "git-svn-id:.*@$commit 3c298f89"`
    [ -n "$commit" ] || exit 
    callgit rebase --onto $name $commit remote-$name
    callgit checkout $name
    callgit merge remote-$name
    callgit branch -D remote-$name
}
# initialize
#------------------------------------------------------

while getopts i:m:qr opt
do
    case $opt in
        i) I=$OPTARG;;
        m) M=$OPTARG;;
        q) Q=1;;
        r) R=1;;
        :) echo "option '-$OPTARG' need a argument.";exit 1;;
        ?) echo "option '-$OPTARG' is invalid.";exit 1;;
        *) echo "...";;
    esac
done

M=${M:-https://}
M=${M%/}
I=${I:-openwrt-temp}
init
update
