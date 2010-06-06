#!/bin/bash
echo -n "copying xchataqua.strings: "
for locale in `ls strings`; do
	if [ $locale = 'en' ]; then
		continue
	fi
	echo -n "$locale "
	cp "strings/$locale/libsg.strings" "lproj/$locale.lproj/"
	cp "strings/$locale/xchataqua.strings" "lproj/$locale.lproj/"
done
echo " /DONE"
