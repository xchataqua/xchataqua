#!/bin/sh
bash po_to_mo.sh
bash copy_mo.sh
ruby po_to_strings.rb
ruby copy_strings.rb

for script in `ls 00?*.sh`; do
	bash $script
done
bash 004_copy_lproj.sh
