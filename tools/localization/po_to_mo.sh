#!/bin/bash
outname=xchat
srcdir=po
outdirbase=../../Localization/locale
for pofile in `ls $srcdir/*.po`; do
	locale=`basename $pofile .po`
	outdir=$outdirbase/$locale/LC_MESSAGES
	outfile="$outdir/$outname.mo"
	srcfile="$srcdir/$locale.po"
	if [ "$outfile" -nt "$srcfile" ]; then
		echo "pass $locale"
		continue
	fi
	mkdir -p $outdir
#	rm $srcdir/$locale.po
#	ln -s ../../../xchat/po/$locale.po $srcdir/$locale.po
	cmd="msgfmt -o $outfile $srcfile"
	echo $cmd
	$cmd
done
