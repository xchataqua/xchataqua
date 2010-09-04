__CURRENT_DIR=`pwd`
cd ../..
xcodebuild -target 'printenv' 2>/dev/null | grep 'setenv' | sed -e 's/^ *setenv //' -e 's/ /=/' > .xcodeenv
. .xcodeenv 2>/dev/null
rm .xcodeenv

cd $__CURRENT_DIR
unset __CURRENT_DIR
