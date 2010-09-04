#!/bin/bash
. set_variables.sh

if [ "$1" = 'clean' ]; then
	rm -rf "$BASE_XIB_STRINGS_DIR"
	exit
fi

mkdir -p "$BASE_XIB_STRINGS_DIR"
for xibfile in "$BASE_XIB_DIR"/*.xib; do
	xibname=`basename "$xibfile"`
	stringsfile="$BASE_XIB_STRINGS_DIR/$xibname.strings"
	if [ "$stringsfile" -nt $xibfile ]; then
		if [ $DEBUG ]; then
			echo "pass $xib"
		fi
		continue # pass if old one
	fi
	cmd_gen="ibtool $IBTOOL_FLAGS --generate-stringsfile '$stringsfile.utf16' '$xibfile'"
	cmd_iconv="iconv -f utf-16 -t utf-8 '$stringsfile.utf16'"
	if [ $DEBUG ]; then
		echo "$cmd_gen && $cmd_iconv > $stringsfile"
	else
		echo -n .
	fi
	eval "$cmd_gen && $cmd_iconv > '$stringsfile'"
done
echo "done"
