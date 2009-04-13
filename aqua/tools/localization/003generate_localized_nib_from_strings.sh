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
    cmd="ibtool --strings-file $strings --write lproj/$locale.lproj/$xib $DEFXIBDIR/$xib"
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
sleep 1
