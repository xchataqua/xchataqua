#!/bin/bash
outname=xchat
srcdir=po
outdirbase=../../fe-aqua/locale
for pofile in `ls $srcdir/*.po`; do
	locale=`basename $pofile .po`
	outdir=$outdirbase/$locale/LC_MESSAGES
	mkdir -p $outdir
#	rm $srcdir/$locale.po
#	ln -s ../../../xchat/po/$locale.po $srcdir/$locale.po
	cmd="msgfmt -o $outdir/$outname.mo $srcdir/$locale.po"
	echo $cmd
	$cmd
done
