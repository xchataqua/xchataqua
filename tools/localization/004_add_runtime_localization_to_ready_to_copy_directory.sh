#!/bin/bash
. set_variables.sh

if [ "$1" = "clean" ]; then
	for lproj in "$LPROJ_DIR"/*; do
		if [ `basename "$lproj" .lproj` == $BASE_LOCALE ]; then
			continue
		fi
		rm -rf "$lproj"/*.strings
	done
	exit;
fi

echo -n "copying xchataqua.strings: "
for localedir in "$MANUAL_STRINGS_DIR"/*; do
	locale=`basename "$localedir"`
	if [ "$locale" = "$BASE_LOCALE" ]; then
		continue
	fi
	echo -n "$locale "
	$CP "$MANUAL_STRINGS_DIR/$locale/libsg.strings" "$LPROJ_DIR/$locale.lproj/"
	$CP "$MANUAL_STRINGS_DIR/$locale/xchataqua.strings" "$LPROJ_DIR/$locale.lproj/"
done
echo "done"
