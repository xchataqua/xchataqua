#!/bin/sh

echo "-generate .mo from .po with 'msgfmt'"
bash po_to_mo.sh
echo ""
#echo "-generate .strings from .po"
#ruby po_to_strings.rb  this script has bug
#echo ""
echo "-copy .strings to Localization"
ruby copy_strings.rb
echo ""
for script in `ls 00?*.sh`; do
	echo "running: $script"
	bash $script
	echo ""
done
