#!/bin/sh

trans_mirror()
{
    local url 
    [ "$1" == "lede" ] &&        url=https://github.com/lede-project/source.git
    [ "$1" == "openwrt" ] &&     url=https://github.com/openwrt/openwrt.git
    [ "$1" == "packages" ] &&    url=https://github.com/openwrt/packages.git
    [ "$1" == "luci" ] &&        url=https://github.com/openwrt/luci.git
    [ "$1" == "routing" ] &&     url=https://github.com/openwrt-routing/packages.git
    [ "$1" == "oldpackages" ] && url=https://git.openwrt.org/packages.git
    [ "$1" == "newpackages" ] && url=https://github.com/openwrt-phoenix/newpackages.git
    [ "$1" == "utils" ] &&       url=https://github.com/openwrt-phoenix/utils.git
    echo -n $url
}

trans_path()
{
    local path 
    [ "$1" == "lede" ] &&        path=./github.com/lede-project/source.git
    [ "$1" == "openwrt" ] &&     path=./github.com/openwrt/openwrt.git
    [ "$1" == "packages" ] &&    path=./github.com/openwrt/packages.git
    [ "$1" == "luci" ] &&        path=./github.com/openwrt/luci.git
    [ "$1" == "routing" ] &&     path=./github.com/openwrt-routing/packages.git
    [ "$1" == "oldpackages" ] && path=./git.openwrt.org/packages.git
    [ "$1" == "newpackages" ] && path=./github.com/openwrt-phoenix/newpackages.git
    [ "$1" == "utils" ] &&       path=./github.com/openwrt-phoenix/utils.git
    echo -n $path
}

mirror()
{
	local mirror="lede openwrt packages luci routing oldpackages newpackages utils"
	local m url path
	for m in $mirror
	do
		url=`trans_mirror $m`
		path=`trans_path $m`
		cd $githome
		if [ -d "$path" ];then
			cd $path
			git remote set-url origin $url
			git fetch -a
		else
			git clone --mirror $url $path
		fi
	done
}
curdir=`pwd`
basedir=`dirname $0`
basedir=`cd $basedir;pwd`
githome=$basedir/git

#----------------------
mirror
