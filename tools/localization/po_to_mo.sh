#!/bin/bash
. set_variables.sh

if [ "$1" = 'clean' ]; then
	rm -rf "$MO_BASE_DIR"/*
	exit
fi

MSGFMT="$PROJECT_DIR/contrib/bin/msgfmt"

moname=xchat

for pofile in `ls $PO_DIR/*.po`; do
	locale=`basename $pofile .po`
	modir="$MO_BASE_DIR/$locale/LC_MESSAGES"
	mofile="$modir/$moname.mo"
	pofile="$PO_DIR/$locale.po"

	#pass routine
	if [ "$mofile" -nt "$pofile" ]; then
		if [ $DEBUG ]; then
			echo "pass $locale"
		fi
		continue
	fi
	
	mkdir -p $modir
	cmd="'$MSGFMT' -o '$mofile' '$pofile'"
	if [ $DEBUG ]; then
		echo $cmd
	else
		echo -n $locale' '
	fi
	eval "$cmd"
done
echo 'done'
