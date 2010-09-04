#!/bin/bash
. set_variables.sh

if [ "$1" == 'clean' ]; then
	for localedir in "$XIB_STRINGS_DIR"/*; do
		if [ `basename $localedir` == $BASE_LOCALE ]; then
			continue
		fi
		rm -rf $localedir
	done
	exit
fi

BASE_SED='002.sed'
SED_TEMP_DIR="$L10N_TEMP_DIR/localesed"

if [ ! -e "$SED_TEMP_DIR" ]; then
	mkdir -p "$SED_TEMP_DIR"
fi

checkdone=''
for po_strings in "$PO_STRINGS_DIR"/*.strings; do
	locale=`basename "$po_strings" .strings`
	if [ $BASE_LOCALE = $locale ]; then
		continue
	fi
	if [ $DEBUG ]; then
		echo -n "generate $locale.sed"
	else
		echo -n $locale
	fi

	#generate sed file
	sedtemp="$SED_TEMP_DIR/$locale.sed"
	echo "#!/bin/sed" > "$sedtemp"
	xibstrings="$MANUAL_STRINGS_DIR/$locale/xib.strings"
	if [ -e "$xibstrings" ]; then
		sed -f "$BASE_SED" "$xibstrings" >> "$sedtemp"
	fi
	sed -f "$BASE_SED" "$PO_STRINGS_DIR/$locale.strings" >> "$sedtemp"

	# generate locale xib strings
	if [ ! -e "$XIB_STRINGS_DIR/$locale" ]; then
		mkdir "$XIB_STRINGS_DIR/$locale"
	fi
	
	for strings in "$BASE_XIB_STRINGS_DIR"/*.xib.strings; do
		newstrings="$XIB_STRINGS_DIR/$locale/"`basename "$strings"`
		if [ "$newstrings" -nt "$strings" ] && [ "$newstrings" -nt "$xibstring" ] && [ "$newstrings" -nt "$PO_STRINGS_DIR/$locale.strings" ]; then
			continue
		fi
		cmd="sed -f '$sedtemp' '$strings'"
		if [ $DEBUG ]; then
			echo "$cmd > '$newstrings' &"
		fi
	 	eval "$cmd > '$newstrings' &"
		checkdone=$checkdone'1'
		echo -n .
	done
	echo ""
	wait $!
done
if [ $checkdone ]; then
	if [ $DEBUG ]; then
		echo 'waiting 2 seconds to syncronize'
	fi
	sleep 2
fi
#eof
