#!/bin/sh
vb=99
jb=`cat /proc/cpuinfo | grep processor | sed '/$/G' | wc -l`
dir=build
goal=menuconfig
while [ -n "$1" ]
do
    case $1 in
        -f) 
        shift
        [ -n "$1" ] && cf=$1
        ;;
        -t) 
        shift
        [ -n "$1" ] && ct=$1
        ;;
        -j) 
        shift
        [ -n "$1" ] && jb=$1
        ;;
        -v)
        shift
        [ -n "$1" ] && vb=$1
        ;;
        *config)
        goal=$1
        shift
        ;;
        *)  opt="$opt $1";;
    esac
    shift
done

[ -f "$cf" ] || exit 1
[ -n "$ct" ] || ct=$cf
[ -f $dir ] && rm -f $dir
[ -d $dir ] || mkdir $dir
[ -f openwrt/Makefile ] || exit 1 
ln -sf ../../feeds openwrt/package/
ln -sf ../openwrt/Makefile $dir/
ln -sf ../openwrt/rules.mk $dir/
ln -sf ../openwrt/Config.in $dir/
ln -sf ../openwrt/scripts $dir/
ln -sf ../openwrt/include $dir/
ln -sf ../openwrt/config $dir/
ln -sf ../openwrt/tools $dir/
ln -sf ../openwrt/toolchain $dir/
ln -sf ../openwrt/target $dir/
ln -sf ../openwrt/package $dir/

rm -f $dir/.config
cp -f $cf $dir/.config
make -C $dir V=$vb $goal -j $jb
[ -f $dir/.config ] || exit 2
cp -f $dir/.config $ct

