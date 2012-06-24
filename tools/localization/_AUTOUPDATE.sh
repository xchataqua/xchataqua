#!/bin/sh

params=$1
if [ "$ACTION" = clean ]; then
	params='clean'
fi

if [ "$params" = 'clean' ]; then
	echo 'clean localizataion files'
fi

. set_variables.sh

echo "-generate .mo from .po with 'msgfmt'"
bash po_to_mo.sh $params
echo ""
#echo "-generate .strings from .po"
#ruby po_to_strings.rb  this script has bug
#echo ""
mkdir -p $COMMON_RES_DIR
echo "-copy .strings to Localization"
ruby copy_strings.rb
echo ""
for script in `ls 00?*.sh`; do
	echo "running: $script $params"
	bash $script $params
	echo ""
done
