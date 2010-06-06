#!/bin/bash
TARGET=../../Localization
for lproj in `ls -d lproj/*.lproj`; do
	if [ ! -e $TARGET/`basename $lproj` ]; then
		mkdir $TARGET/`basename $lproj`
	fi
	echo -n "copying $lproj"
	for xib in `ls -d $lproj/*.xib`; do
		tgt=$TARGET/`basename $lproj`/`basename $xib`
		if [ $tgt -nt $xib ]; then
			continue
		fi
		cmd="cp $xib $tgt"
		if [ $DEBUG ]; then
			echo $cmd;
		fi
		$cmd
		echo -n .
	done
	strings="$lproj/xchataqua.strings"
	if [ -e "$strings" ]; then
		cp "$strings" "$TARGET/`basename $lproj`/"
		echo -n "'"
	fi
	echo ""
done
