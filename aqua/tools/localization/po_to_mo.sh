#!/bin/bash
outname=xchat
srcdir=po
outdirbase=locale
for pofile in `ls $srcdir/*.po`; do
	locale=`basename $pofile .po`
	outdir=$outdirbase/$locale/LC_MESSAGES
	mkdir -p $outdir
	cmd="msgfmt -o $outdir/$outname.mo $srcdir/$locale.po"
	echo $cmd
	$cmd
done
