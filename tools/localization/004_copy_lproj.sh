#!/bin/bash
TARGET=../../fe-aqua
for lproj in `ls -d lproj/*.lproj`; do
	if [ ! -e $TARGET/`basename $lproj` ]; then
		mkdir $TARGET/`basename $lproj`
	fi
	echo -n $lproj
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
	echo ""
done
