#!/bin/bash

VERSTRING=$(git describe --tags --long)
HEADER=$1
XCCONFIG=$2

if [ $# -lt 2 ]; then
	echo "Not enough parameters."
	exit 1
fi

MAJOR=`echo $VERSTRING | cut -d'.' -f1`
MINOR=`echo $VERSTRING | cut -d'.' -f2`
REVIS=`echo $VERSTRING | cut -d'.' -f3 | cut -d'-' -f 1`
TINYBUILD=`echo $VERSTRING | cut -d'-' -f2`
RC=
if [ $(echo $TINYBUILD | grep rc) ]; then
	# We've got a release candidate. Reparse to get the build -number-.
	RC=-$TINYBUILD
	TINYBUILD=`echo $VERSTRING | cut -d'-' -f3`
fi

VERSTRING=$(git describe --tags)

rm -f $HEADER.tmp

cat >> $HEADER.tmp << __eof__
#ifndef __included_build_number_h
#define __included_build_number_h

#define XCHAT_AQUA_VERSION_MAJOR $MAJOR
#define XCHAT_AQUA_VERSION_MINOR $MINOR
#define XCHAT_AQUA_VERSION_REVISION $REVIS
#define XCHAT_AQUA_VERSION_BUILD $TINYBUILD
#define XCHAT_AQUA_VERSION "$VERSTRING"

#endif
__eof__

rm -f $XCCONFIG.tmp

cat >> $XCCONFIG.tmp << __eof__
XCHAT_AQUA_VERSION = $VERSTRING
__eof__

FILES="$XCCONFIG $HEADER"

for a in $FILES; do

	if [ -f $a ]; then
	        if [ -x /sbin/md5 ]; then
	                MD5OLD=`/sbin/md5 $a | cut -d' ' -f4`
	        else
	                MD5OLD=`md5sum $a | cut -d' ' -f1`
        	fi
	else
        	MD5OLD=
	fi

	if [ -x /sbin/md5 ]; then
		MD5NEW=`/sbin/md5 $a.tmp | cut -d' ' -f4 2> /dev/null`
	else
		MD5NEW=`md5sum $a.tmp | cut -d' ' -f1 2> /dev/null`
	fi

	if [ "$MD5NEW" == "$MD5OLD" ]; then
		echo "$a is already up to date"
		rm -f $a.tmp
	else
		echo "$a updated"
		mv $a.tmp $a
	fi

done
