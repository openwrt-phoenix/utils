#!/bin/sh

for name in openwrt/package feeds/{luci/applications,packages,routing,newpackages,oldpackages}
do
    find $name -name 'Makefile' | sed -e '/\/files\/\|\/src\//d' -e 's/\/Makefile$//' | sort >path.txt
    sed -e 's/.*\///' path.txt >>list.txt
    sort list.txt > list.txt.tmp
    sort -u list.txt.tmp >list.txt
    diff -b -B list.txt list.txt.tmp | sed -e '/^> /!d' -e 's@^> @@' |
    while read item
    do  
        [ -n "${item}" ] || continue
        sed "/\/${item}\$/!d" path.txt | 
        while read item1
        do  
            echo ${item1}
            rm -rf ${item1}
        done
    done
    find ${name} -type d -empty -delete
done
rm -f list.txt list.txt.tmp path.txt
