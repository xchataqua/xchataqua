__CURRENT_DIR=`pwd`

if [ ! "$PROJECT_FILE" ]; then
	echo 'NO PROJECT GIVEN: Set $PROJECT_FILE before run this script'
	exit -1
fi

xcodebuild -project "$PROJECT_FILE" -target 'printenv' 2>/dev/null | grep 'setenv' | sed -e 's/^ *setenv //' -e 's/ /=/' > .xcodeenv
. .xcodeenv 2>/dev/null
rm .xcodeenv

cd $__CURRENT_DIR
unset __CURRENT_DIR
