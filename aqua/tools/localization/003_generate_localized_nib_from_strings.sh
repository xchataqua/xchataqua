#!/bin/bash
BASELOCALE=en
DEFXIBDIR=../../fe-aqua/en.lproj

for locale in `ls -d lproj/*`; do
  locale=`basename $locale`
	if [ $locale != `basename $locale .lproj` ]; then
		continue;
	fi
	if [ $BASELOCALE = $locale ]; then
    continue;
  fi
	echo -n $locale
	for strings in `ls lproj/$locale/*.xib.strings`; do
    xib=`basename $strings .strings`
		if [ ! -e lproj/$locale.lproj ]; then
			mkdir lproj/$locale.lproj
		fi
		if [ $strings -ot lproj/$locale.lproj/$xib ]; then
			if [ $DEFXIBDIR/$xib -ot lproj/$locale.lproj/$xib ]; then
				continue
			fi
		fi
    cmd="ibtool --strings-file $strings --write lproj/$locale.lproj/$xib $DEFXIBDIR/$xib"
#		diff lproj/$locale/$xib lproj/$locale.lproj/$xib
#		if [ $? ]; then
#			cp lproj/$locale/$xib lproj/$locale.lproj/$xib
#		fi
		if [ $DEBUG ]; then
	    echo "$cmd"
		fi
    $cmd &
		echo -n .
  done
	echo ""
	cp $DEFXIBDIR/ChanList.xib lproj/$locale.lproj/
	wait $!
done
sleep 3
