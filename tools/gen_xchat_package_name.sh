#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

cd "$DIR/../xchat"
REV=`git log --grep='https://xchat.svn.sourceforge.net/svnroot/xchat' --fixed-strings --max-count=1 | tail -n 1 | sed 's/^.*@\([0-9]*\) .*$/\1/'`

echo '/* Define to the full name and version of this package. */'
echo '#define PACKAGE_STRING "XChat 2.8.8-svn'$REV'"'
echo ''
echo '/* Define to the version of this package. */'
echo '#define PACKAGE_VERSION "2.8.8-svn'$REV'"'
