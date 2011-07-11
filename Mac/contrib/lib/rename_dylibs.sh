#!/bin/sh
PREFIX='@executable_path/../Frameworks/'
for f in *.dylib; do
	oldid=`otool -L "$f" | sed -ne '2s/^	\(.*\) (.*$/\1/p'`
	newid=$PREFIX`basename "$oldid"`
	install_name_tool -id "$newid" "$f"
	for sym in `otool -L "$f" | sed -ne '3,$s/^	\(.*\) (.*$/\1/p'`; do
		if [ `dirname "$sym"` = "/opt/local/lib" ]; then
			install_name_tool -change "$sym" $PREFIX`basename "$sym"` "$f"
		fi
	done
	echo $f done
done
