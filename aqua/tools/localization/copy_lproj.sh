#!/bin/bash
TARGET=../../fe-aqua
for lproj in `ls -d lproj/*.lproj`; do
	cmd="cp $lproj/* $TARGET/`basename $lproj`/"
	if [ $DEBUG ]; then
		echo $cmd;
	fi
	$cmd
done
