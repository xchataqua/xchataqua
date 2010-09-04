#!/bin/bash
. set_variables.sh

if [ "$LPROJ_DIR" = "$XIB_DIR" ]; then
	echo "pass copy phase because source dir is the target dir"
	exit;
fi

if [ "$1" = 'clean' ]; then
	for lproj in "$XIB_DIR"/*; do
		if [ `basename "$lproj" .lproj` == $BASE_LOCALE ]; then
			continue
		fi
		rm -rf "$lproj"
	done
	exit
fi

for lproj in "$LPROJ_DIR/*.lproj"; do
	xibdir="$XIB_DIR"/`basename "$lproj"`
	if [ ! -e "$xibdir" ]; then
		mkdir "$xibdir"
	fi
	
	echo -n "copying $lproj"
	for xibtemp in "$lproj/*.xib"; do
		xibfile=$xibdir/`basename $xibtemp`
		if [ $xibfile -nt $xibtemp ]; then
			continue
		fi
		cmd="$CP $xibtemp $xibfile"
		if [ $DEBUG ]; then
			echo $cmd;
		else
			echo -n .
		fi
		eval "$cmd"
	done
	for strings in "$lproj/*.strings"; do
		cmd="$CP '$strings' '$xibdir/'"
		if [ $DEBUG ]; then
			echo "$cmd"
		else
			echo -n "_"
		fi
		eval "$cmd"
	done
	echo ""
done
