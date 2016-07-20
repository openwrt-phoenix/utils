#!/bin/sh

drop_shell()
{
    local n=$1
    echo "==need merge: "
    if /bin/bash; then
        echo "==seems ok, try commit!"
        callgit commit
    else
        echo "==seems fail, rollback!"
        callgit reset --hard
        callgit checkout $n
        exit 0
    fi
}


call_git()
{
    local q= o=$1
    [ "$o" == "subtree" ] && o=$2
    case "$o" in
        merge|pull) q=$quiet;;
        *);;
    esac
    eval "echo '--> git' $@" >&2
    if [ -n "$q" ];then
        git "$@" | grep '^Merge'
        return ${PIPESTATUS[0]}
    else
        git "$@"
        return $?
    fi
}

trans_branch()
{
    local o
    case $1 in
    a|aa) o=12.09;;
    b|bb) o=14.07;;
    c|cc) o=15.05;;
    m|mm) o=master;;
    12.09|14.07|15.05|master) o=$1;;
    *) o='';;
    esac
    echo -n $o
}

check_branch()
{
    if [ "$vender" == "openwrt" ];then
        case $branch in
        12.09|14.07|15.05|master);;
        *) echo "vender $vender has no branch $branch !" >&2;exit 1;
        esac
    elif [ "$vender" == "lede" ];then
        case $branch in
        master);;
        *) echo "vender $vender has no branch $branch !" >&2;exit 1;
        esac
    else
        echo "has not vender $vender !" >&2;exit 1;
    fi
}

trans_branch2()
{
    local o
    [ $1 == openwrt ] && [ $2 == 12.09 ] && o=attitude_adjustment
    [ $1 == openwrt ] && [ $2 == 14.07 ] && o=barrier_breaker
    [ $1 == openwrt ] && [ $2 == 15.05 ] && o=chaos_calmer
    [ $1 == luci ] && [ $2 == 14.07 ] && o=luci-0.12
    [ $1 == newpackages ] && o=master
    [ $1 == oldpackages ] && o=master
    [ $1 == utils ] && o=master
    [ $2 == master ] && o=master
    [ -n "$o" ] || o=for-$2
    echo -n $o
}

trans_vender()
{
    local o
    case $1 in
    o) o=openwrt;;
    l) o=lede;;
    openwrt|lede) o=$1;;
    *) o='';;
    esac
    echo -n $o
}

trans_mirror()
{
    local url
    case $1 in
    *-lede)        url=$mirror/github.com/lede-project/source.git;;
    *-openwrt)     url=$mirror/github.com/openwrt/openwrt.git;;
    *-packages)    url=$mirror/github.com/openwrt/packages.git;;
    *-luci)        url=$mirror/github.com/openwrt/luci.git;;
    *-routing)     url=$mirror/github.com/openwrt-routing/packages.git;;
    *-newpackages) url=$mirror/github.com/openwrt-phoenix/newpackages.git;;
    *-utils)       url=$mirror/github.com/openwrt-phoenix/utils.git;;
    *-oldpackages) url=$mirror/git.openwrt.org/packages.git;;
    *);;
    esac
    echo -n $url
}

trans_remote()
{
    local o
    if [ "$vender" == "lede" -a "$1" == "openwrt" ];then
        o="origin-lede"
    else
        o="origin-$1"
    fi
    echo -n $o
}

trans_subtree()
{
    local o
    case $1 in
    lede|openwrt) o=openwrt;;
    packages|luci|routing|oldpackages|newpackages) o=feeds/$1;;
    utils) o=$1;;
    *);;
    esac
    echo -n $o
}

main_init()
{
    # initialize
    #------------------------------------------------------
    local opts=':fiqrub:d:m:v:'
    local opt OPTARG init update
    remotes='utils openwrt packages luci routing oldpackages newpackages'
    branch=master
    destdir=phoenix
    mirror=https://
    vender=openwrt
    while getopts $opts opt
    do
        case $opt in
        f) force=1;;
        i) init=1;;
        q) quiet=1;;
        r) remove=1;;
        u) update=1;;
        b) branch=$OPTARG;;
        d) destdir=$OPTARG;;
        m) mirror=$OPTARG;;
        v) vender=$OPTARG;;
        :) echo "option '-$OPTARG' need a argument.";exit 1;;
        ?) echo "option '-$OPTARG' is invalid.";exit 1;;
        *) echo "...";;
        esac
    done
    mirror=${mirror%/}
    vender=`trans_vender $vender`
    branch=`trans_branch $branch`
    check_branch
    [ -n "$init" ] && utils_init
    [ -n "$update" ] && utils_update
}    


utils_init()
{
    local o=$vender
    mkdir -p $destdir
    [ -d "$destdir" -a -n "$force" ] && find $destdir -maxdepth 1 -mindepth 1 |xargs rm -rf 
    cd $destdir
    if [ ! -d ".git" ];then 
        call_git init .
        call_git config merge.renameLimit 65536
        mkdir -p defconfig
        touch .gitignore README.md defconfig/README.md
        echo '*.o' >.gitignore
        echo '*.orig' >>.gitignore
        echo '*.rej' >>.gitignore
        echo '.*.swp' >>.gitignore
        echo '.*.log' >>.gitignore
        echo '.tags' >>.gitignore
        echo 'tags' >>.gitignore
        echo '/build' >>.gitignore
        echo "$vender-$branch" >README.md
        call_git add .
        call_git commit -m 'Initialization repository'
    fi
    return 0
    vender=openwrt
    git branch | grep -q "$vender-$branch" && return 1
    for remote in $remotes
    do
        set_env
        set_remote
        call_git fetch -n $remote #$branch2
        echo "------------------------------------------------------"
    done
    vender=lede
    remote=openwrt
    set_env
    set_remote
    call_git fetch -n $remote #$branch2

    #call_git subtree add --squash --prefix=openwrt        da75170 #d303b27 #41863
    #call_git subtree add --squash --prefix=feeds/packages 1ab5d36
    #call_git subtree add --squash --prefix=feeds/luci     3ccdaa9
    #call_git subtree add --squash --prefix=feeds/routing  ba11f8d
    #call_git subtree add --squash --prefix=feeds/oldpackages  1b9848d
    #call_git branch bb
    #call_git subtree merge --squash --prefix=openwrt        6c9b1a2 #2823965 #45973
    #call_git subtree merge --squash --prefix=feeds/packages f55314d
    #call_git subtree merge --squash --prefix=feeds/luci     e11b5e4
    #call_git subtree merge --squash --prefix=feeds/routing  e269421
    call_git subtree add --squash --prefix=openwrt            6c9b1a2 #2823965 #45973
    call_git subtree add --squash --prefix=feeds/packages     f55314d
    call_git subtree add --squash --prefix=feeds/luci         e11b5e4
    call_git subtree add --squash --prefix=feeds/routing      e269421
    call_git subtree add --squash --prefix=feeds/newpackages  bdcbb26
    call_git subtree add --squash --prefix=feeds/oldpackages  1b9848d
    vender=openwrt
    call_git branch $vender-`trans_branch cc`
    call_git branch $vender-`trans_branch mm`
    call_git reset --hard HEAD~5
    call_git subtree add --squash --prefix=openwrt            b20a2b4 #2823965 #45973
    call_git subtree add --squash --prefix=feeds/packages     f55314d
    call_git subtree add --squash --prefix=feeds/luci         e11b5e4
    call_git subtree add --squash --prefix=feeds/routing      e269421
    call_git subtree add --squash --prefix=feeds/newpackages  bdcbb26
    call_git subtree add --squash --prefix=feeds/oldpackages  1b9848d
    vender=lede
    call_git branch $vender-`trans_branch mm`
}


utils_update()
{
    :
}

set_env()
{
    local p
    branch2=`trans_branch2 $remote $branch`
    subtree=`trans_subtree $remote`
    remote=`trans_remote $remote`
    echo "==remote=$remote,vender=$vender,branch=$branch,branch2=$branch2,subtree=$subtree"
}

set_remote()
{
    local url=`trans_mirror $remote`
    if git remote | grep -q "^$remote$"; then
        if [ -n "$force" ]; then
            call_git remote remove $remote
            call_git remote add $remote $url
        else
            call_git remote set-url $remote $url
        fi
    else
        call_git remote add $remote $url
    fi
}

# define
#------------------------------------------------------

export LANG=en_US.UTF-8
export EDITOR=:

curdir=`pwd`
basedir=`dirname $0`
basedir=`(cd $basedir; pwd)`

#PS4='+[$BASH_SOURCE][$LINENO][$FUNCNAME]:'
#echo ${FUNCNAME[@]}
#echo '$FUNCNAME='$FUNCNAME
#echo '${#FUNCNAME[@]}='${#FUNCNAME[@]}
#echo '${FUNCNAME[@]}='${FUNCNAME[@]}
#echo '$LINENO='$LINENO
#echo '$PS4='$PS4
#echo '${#BASH_LINENO[@]}='${#BASH_LINENO[@]}
#echo '${BASH_LINENO[@]}='${BASH_LINENO[@]}
#echo '$RANDOM='$RANDOM
#echo '${BASH_SOURCE[@]}='${BASH_SOURCE[@]}
#echo '$DIRSTACK='$DIRSTACK
#echo '$BASH_ARGC='$BASH_ARGC
#echo '${PIPESTATUS[@]}='${PIPESTATUS[@]}
#echo '$PPID='$PPID
#echo '$COLUMNS='$COLUMNS
#echo '$LINES'=$LINES
#set

# entry
#------------------------------------------------------
main_init "$@"
