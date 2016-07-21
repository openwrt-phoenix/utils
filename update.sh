#!/bin/sh

drop_shell()
{
    if call_git status | grep -q conflicts; then
        syslog "==fix conflicts: "
        PS1='fix conflicts \s-\v\$ ' /bin/bash
        if call_git status | grep -q 'All conflicts fixed'; then
            syslog "==seems ok, try commit!"
            if call_git commit; then
                return 0
            else
                syslog "commit fail, rollback!"
            fi
        elif call_git status | grep -q 'working directory clean';then
            syslog "==seems ok, is committed?"
            return 0
        else
            syslog "==seems fail, rollback!"
        fi
    fi
    call_git reset --hard
    call_git checkout $1
    exit 1
}


call_git()
{
    local o=$1
    [ "$o" == "subtree" ] && o=$2
    syslog "# git $@"
    if [ -n "$quiet" -a "$o" == "merge" ] || [ -n "$quiet" -a "$o" == "pull" ];then
        git "$@" | grep '^Merge'
        return ${PIPESTATUS[0]}
    else
        git "$@"
        return $?
    fi
}

get_venders()
{
    echo -n "openwrt lede"
}

get_branchs()
{
    local o
    case "$1" in
        openwrt)
            o="14.07 15.05 master";;
        lede)
            o="master";;
        *)
            o="";;
    esac
    echo -n $o
}

trans_branch()
{
    local o
    case $1 in
        b|bb)
            o=14.07;;
        c|cc)
            o=15.05;;
        m|mm)
            o=master;;
        12.09|14.07|15.05|master)
            o=$1;;
        *)
            o='';;
    esac
    echo -n $o
}

check_options()
{
    [ "$vender" == "" -a "$branch" == "" ] && return 0
    if [ "$vender" == "openwrt" ];then
        [ "$branch" == "" ] && return 0
        case "$branch" in
            12.09)
                syslog "vender $vender branch $branch is not supported!";exit 1;;
            14.07|15.05|master)
                ;;
            *)
                syslog "vender $vender has no branch $branch !";exit 1;;
        esac
    elif [ "$vender" == "lede" ];then
        [ "$branch" == "" ] && return 0
        case "$branch" in
            master)
                ;;
            *)
                syslog "vender $vender has no branch $branch !";exit 1;;
        esac
    elif [ "$vender" == "" -a  -n "$branch" ];then
        syslog "vender is need for branch !";exit 1;
    else
        syslog "has not vender $vender !";exit 1;
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
        o)
            o=openwrt;;
        l)
            o=lede;;
        openwrt|lede)
            o=$1;;
        *)
            o='';;
    esac
    echo -n $o
}

trans_mirror()
{
    local url
    [ "$1" == "lede" ] &&        url=$mirror/github.com/lede-project/source.git
    [ "$1" == "openwrt" ] &&     url=$mirror/github.com/openwrt/openwrt.git
    [ "$1" == "packages" ] &&    url=$mirror/github.com/openwrt/packages.git
    [ "$1" == "luci" ] &&        url=$mirror/github.com/openwrt/luci.git
    [ "$1" == "routing" ] &&     url=$mirror/github.com/openwrt-routing/packages.git
    [ "$1" == "oldpackages" ] && url=$mirror/git.openwrt.org/packages.git
    [ "$1" == "newpackages" ] && url=$mirror/github.com/openwrt-phoenix/newpackages.git
    [ "$1" == "utils" ] &&       url=$mirror/github.com/openwrt-phoenix/utils.git
    echo -n $url
}

trans_remote()
{
    local o="origin-$1"
    [ "$2" == "lede" -a "$1" == "openwrt" ] && o="origin-$2"
    echo -n $o
}

trans_subtree()
{
    local o
    case $1 in
        lede|openwrt)
            o=openwrt;;
        utils)
            o=$1;;
        packages|luci|routing|oldpackages|newpackages)
            o=feeds/$1;;
        *);;
    esac
    echo -n $o
}

trans_commit()
{
    local o _vender=$1 _branch=$2 _remote=$3
    local _openwrt_14_07_openwrt=da75170
    local _openwrt_14_07_packages=1ab5d36
    local _openwrt_14_07_luci=3ccdaa9
    local _openwrt_14_07_routing=ba11f8d
    local _openwrt_14_07_oldpackages=1b9848d
    local _openwrt_14_07_newpackages=bdcbb26
    local _openwrt_14_07_utils=6bb8dbd
    local _openwrt_15_05_openwrt=6c9b1a2
    local _openwrt_15_05_packages=f55314d
    local _openwrt_15_05_luci=e11b5e4
    local _openwrt_15_05_routing=e269421
    local _lede_master_openwrt=b20a2b4
    [ "$_remote" == "oldpackages" ] && _branch=14.07 
    [ "$_remote" == "newpackages" ]  && _branch=14.07
    [ "$_remote" == "utils" ] && _branch=14.07
    [ "$_vender" == "lede" -a "$_remote" != "openwrt" ] && _vender=openwrt
    [ "$_branch" == "master" -a "$_vender$_remote" != "ledeopenwrt" ] && _branch=15.05
    eval "o=\$_${_vender}_${_branch/./_}_${_remote}"
    echo -n $o  
}

main_init()
{
    # initialize
    #------------------------------------------------------
    local opts=':cfiqruxb:d:m:v:'
    local opt OPTARG init update
    remotes='openwrt packages luci routing oldpackages newpackages utils'
    #branch=master
    destdir=phoenix
    mirror=https://
    #vender=openwrt
    while getopts $opts opt
    do
        case $opt in
            c)
                clean=1;;
            f)
                force=1;;
            i)
                init=1;;
            q)
                quiet=1;;
            r)
                remove=1;;
            u)
                update=1;;
            x)
                debug=1;;
            b)
                branch=$OPTARG;;
            d)
                destdir=$OPTARG;;
            m)
                mirror=$OPTARG;;
            v)
                vender=$OPTARG;;
            :)
                syslog "option '-$OPTARG' need a argument.";exit 1;;
            ?)
                syslog "option '-$OPTARG' is invalid.";exit 1;;
            *)
                syslog "...";;
        esac
    done
    [ "$debug" == 1 ] && { force=;set -x; }
    mirror=${mirror%/}
    vender=`trans_vender $vender`
    branch=`trans_branch $branch`
    check_options
    [ -n "$clean" -a -n "$init" ] && utils_clean
    [ -n "$init" ] && utils_init
    [ -n "$update" ] && utils_update
}    

utils_clean()
{
    local _remote _subtree
    [ -d "$destdir" -a -d "$destdir/.git" ] || return 0
    cd $destdir
    call_git branch | grep -q . || return 0
    call_git branch | grep -v '.*-master' | grep -q master || call_git branch master
    call_git checkout master
    call_git reset --hard `call_git log --pretty=%h | tail -n 1`
    for _remote in $remotes
    do
        _subtree=`trans_subtree $_remote`
        [ -d "$_subtree" ] && syslog "remove $_subtree" && rm -rf $_subtree
    done
    call_git branch | 
    while read item
    do
        [ "$item" == "* master" ] && continue
        call_git branch -D "$item"
    done
    cd $curdir
}

utils_init()
{
    local _vender _venders _remote _branch _branch2 _branchs _subtree _commit
    mkdir -p $destdir
    [ -d "$destdir" -a -n "$force" ] && find $destdir -maxdepth 1 -mindepth 1 |xargs rm -rf 
    cd $destdir
    if [ ! -d ".git" ];then 
        call_git init .
        call_git config merge.renameLimit 65536
        mkdir -p defconfig
        touch .gitignore README.md defconfig/README.md
        echo -e '*.o\n*.orig\n*.rej\n*.swp\n.*.log\n.tags\n/build' >.gitignore
        call_git add .
        call_git commit -m 'Initialization repository'
    else
        call_git branch | grep -q "openwrt-\|lede-" && return 1
        [ `call_git log --pretty=%h | wc -l` -gt 1 ] && return 1
    fi
    for _remote in $remotes lede
    do
        echo "------------------------------------------------------"
        _subtree=`trans_subtree $_remote`
        [ -d "$_subtree" ] && syslog "subtree $_subtree is exists!" && exit 1
        set_remote $_remote
        call_git fetch -n `trans_remote $_remote` || return 1
    done
    echo "------------------------------------------------------"
    _venders=$vender
    [ -n "$_venders" ] || _venders=`get_venders`
    for _vender in $_venders
    do
        _branchs=$branch
        [ -n "$_branchs" ] || _branchs=`get_branchs $_vender` 
        call_git reset --hard `call_git log --pretty=%h | tail -n 1`
        for _branch in $_branchs
        do
            for _remote in $remotes
            do
                echo "------------------------------------------------------"
                _subtree=`trans_subtree $_remote`
                _commit=`trans_commit $_vender $_branch $_remote`
                if [ -d "$_subtree" ];then
                    call_git subtree merge --squash --prefix=$_subtree $_commit || return 1
                else
                    call_git subtree add --squash --prefix=$_subtree $_commit || return 1
                fi
                sleep 1
            done
            call_git branch $_vender-$_branch
            echo "======================================================"
            #[ "$_vender" == "$vender" -a "$_branch" == "$branch" ] && break 2
        done
    done
    cd $curdir
}


utils_update()
{
    local _vender _venders _remote _remote2 _branch _branch2 _branchs _subtree
    [ -d "$destdir" -a -d "$destdir/.git" ] || return 0
    cd $destdir
    _venders=$vender
    [ -n "$_venders" ] || _venders=`get_venders`
    for _vender in $_venders
    do
        _branchs=$branch
        [ -n "$_branchs" ] || _branchs=`get_branchs $_vender` 
        for _branch in $_branchs
        do
            call_git checkout $_vender-$_branch
            call_git branch | grep -v '.*-master' | grep -q master && call_git branch -D master
            call_git checkout $_vender-$_branch -b master
            for _remote in $remotes
            do
                echo "------------------------------------------------------"
                _subtree=`trans_subtree $_remote`
                _branch2=`trans_branch2 $_remote $_branch`
                _remote2=`trans_remote $_remote`
                set_remote $_remote
                call_git subtree pull --squash --prefix=$_subtree $_remote2 $_branch2 || drop_shell $_vender-$_branch
            done
            echo "------------------------------------------------------"
            call_git checkout $_vender-$_branch
            call_git merge master
            call_git branch -D master
            echo "======================================================"
        done
    done
    cd $curdir
}

set_remote()
{
    local _remote=`trans_remote $1`
    local _url=`trans_mirror $1`
    if git remote | grep -q "^$_remote$"; then
        if [ -n "$force" ]; then
            call_git remote remove $_remote
            call_git remote add $_remote $_url
        else
            call_git remote set-url $_remote $_url
        fi
    else
        call_git remote add $_remote $_url
    fi
}

# syslog
exec 3>&1
syslog()
{
    echo "$@" >&3
}

# define
#------------------------------------------------------

export LANG=en_US.UTF-8
export EDITOR=:

curdir=`pwd`
basedir=`dirname $0`
basedir=`(cd $basedir; pwd)`

# entry
#------------------------------------------------------
main_init "$@"
