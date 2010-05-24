#!/bin/bash
if [ ! -f '/System/Library/Perl/5.8.8' ]; then
	sudo tar xvf "$PROJECT_DIR/contrib/systemlib/Perl-Leopard.tar" -P
fi
