#!/bin/bash
. set_variables.sh

if [ "$1" = "clean" ]; then
	for lproj in "$LPROJ_DIR"/*; do
		if [ `basename "$lproj" .lproj` == $BASE_LOCALE ]; then
			continue
		fi
		rm -rf "$lproj"
	done
	exit;
fi

checkdone=''
if [ ! -e "$LPROJ_DIR" ]; then
	mkdir -p "$LPROJ_DIR"
fi
for xibstringslocale in "$XIB_STRINGS_DIR"/*; do
	locale=`basename "$xibstringslocale"`
	if [ $BASE_LOCALE = $locale ]; then
	   continue;	# pass base locale
	fi

	echo -n "$locale"
	lprojdir="$LPROJ_DIR/$locale.lproj"
	if [ ! -e "$lprojdir" ]; then
		mkdir "$lprojdir"
	fi
	for strings in "$xibstringslocale"/*.xib.strings; do
		# strings: generated one
		xibname=`basename "$strings" .strings`
		xibfile="$lprojdir/$xibname"
		
		if [ "$xibfile" -nt "$BASE_XIB_DIR/$xibname" ]; then
			if [ "$xibfile" -nt "$strings"  ]; then # base is older
				continue
			fi
		fi
		cmd="ibtool $IBTOOL_FLAGS --strings-file '$strings' --write '$xibfile' '$BASE_XIB_DIR/$xibname'"
		checkdone='1'
		if [ $DEBUG ]; then
			echo "$cmd &"
		else
			echo -n .
		fi
		eval "$cmd &"
	done
	echo " waiting sync"
	wait $!
done
if [ $checkdone ]; then
	sleep 2
fi
