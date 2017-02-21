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

mkdir -p "${L10N_TEMP_DIR}"

for po in "$PO_DIR"/*.po; do
	locale=`basename ${po} .po`
	if [ ${BASE_LOCALE} = ${locale} ]; then
		continue
	fi
    echo -n "${locale} "

    strings="${L10N_TEMP_DIR}/$locale.strings"
    echo '' > "${strings}"
	app_strings="$MANUAL_STRINGS_DIR/$locale/xib.strings"
    if [ -e "$app_strings" ]; then
        cat "${app_strings}" >> "${strings}"
    fi
	app_strings="$MANUAL_STRINGS_DIR/$locale/xchataqua.strings"
    if [ -e "$app_strings" ]; then
        cat "${app_strings}" >> "${strings}"
    fi

    lprojdir="$LPROJ_DIR/$locale.lproj"
    if [ ! -e "$lprojdir" ]; then
        mkdir -p "$lprojdir"
    fi

    for xib_strings in ${LPROJ_DIR}/${BASE_LOCALE}.lproj/*.strings; do
        xib_strings_basename=`basename ${xib_strings}`
        xib_strings_target="${lprojdir}/${xib_strings_basename}"
        if [ 1 ]; then
        #if [ "${xib_strings}" -nt "${xib_strings_target}" ]; then
            ./apply_localizable_strings.py "${xib_strings}" "${po}" "${strings}" > "${xib_strings_target}"
            echo -n .
        else
            echo -n s
        fi
	done

    if [ -e "$MANUAL_STRINGS_DIR/$locale/xchataqua.strings" ]; then
        cp "$MANUAL_STRINGS_DIR/$locale/xchataqua.strings" "${lprojdir}/"
    fi
	echo ""
done
if [ $checkdone ]; then
	if [ $DEBUG ]; then
		echo 'waiting 2 seconds to syncronize'
	fi
	sleep 2
fi
#eof
