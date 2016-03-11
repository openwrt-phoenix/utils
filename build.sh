#!/bin/sh
cf=
cl=
df=
jb=`cat /proc/cpuinfo | grep processor | sed '/$/G' | wc -l`
vb=99
dir=build

if [ `ps --no-headers -oppid -p$$` -gt 1 ]; then
    name=`basename $0`
    ppid=`ps --no-headers -oppid -p$$`
    if [ `ps --no-headers -ocomm -p$ppid` != $name ];then
        $0 $@ 
        sleep 1
        tail --pid=`fuser ${name%%.*}.log 2>&1 | awk -F\  '{print $2}'` -f ${name%%.*}.log
        exit 0
    else
        exec 0</dev/null
        exec 1>.${name%%.*}.log
        exec 2>&1
        setsid $0 $@ &
        exit 0 
    fi
fi

while [ -n "$1" ]
do
    case $1 in
        -f) 
        shift
        [ -n "$1" ] && cf=$1
        ;;
        -c) cl=1;;
        -d) dc=1;;
        -j) 
        shift
        [ -n "$1" ] && jb=$1
        ;;
        -v)
        shift
        [ -n "$1" ] && vb=$1
        ;;
        *)  opt="$opt $1";;
    esac
    shift
done

if [ -n "$dc" ]; then
    rm -rf download
    rm -rf release
fi
if [ -n "$dc$cl" ]; then
    rm -rf $dir
    rm -f openwrt/scripts/config/zconf.lex.c
    rm -f openwrt/scripts/config/mconf_check
    rm -rf openwrt/key-build openwrt/key-build.pub
fi

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

[ -n "$cf" ] && [ ! -f "$cf" ] && echo "File [ $cf ] not exists!" && exit 1
[ -n "$cf" ] && [ -f "$cf" ] && cp $cf $dir/.config
[ ! -f $dir/.config ] && echo "File [ .config ] not exists!" && exit 1
sed -e '/CONFIG_\(BINARYi\|DOWNLOAD\)_FOLDER/d' \
    -e '/CONFIG_LOCALMIRROR/d' \
    -e '/CONFIG_BUILD_LOG/d' -i $dir/.config
cat >>$dir/.config <<EOF
CONFIG_BINARY_FOLDER="\$(TOPDIR)/release/\$(BOARD)"
CONFIG_DOWNLOAD_FOLDER="\$(TOPDIR)/download"
CONFIG_LOCALMIRROR="http://192.168.19.197/openwrt/download.php"
CONFIG_BUILD_LOG=y
EOF
mkdir -p $dir/tmp
find $dir/tmp -maxdepth 1 -name 'debug-*.txt' -delete
export PATH=$PWD/utils:$PATH
printf "==%18s==========================================\n" "`date +'%Y-%m-%d %H:%M:%S'`"
t1=`date +%s`

./openwrt/scripts/getver.sh > ./$dir/version
make -C $dir -j $jb V=$vb $opt

t2=`date +%s`
printf "==%18s==========================================\n" "`date +'%Y-%m-%d %H:%M:%S'`"
t3=`echo "($t2 - $t1) / 60" | bc`
printf "==%18dm==========================================\n" $t3
