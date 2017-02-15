#!/bin/bash

SANDBOX=~/"Library/Containers/org.3rddev.xchatazure/Data/Library/Application Support/XChat Azure"
AZURE=~/"Library/Application Support/XChat Azure"
AQUA=~/"Library/Application Support/X-Chat Aqua"
XCHAT=~/".xchat2"

if [ ! -h "$SANDBOX" ]; then
	if [ -d "$SANDBOX" ]; then
		echo "Your data is OK :)"
	else
		echo "This is unfixable. Did you manually touch your directory?"
	fi
	exit
fi

echo "Your real data is symlinked... This may cause critical problems..."
rm "$SANDBOX"

echo "Try on $XCHAT"
if [ -d "$XCHAT" ]; then
	echo "Data found on $XCHAT"
	if [ ! -h "$XCHAT" ]; then
		cp -R "$XCHAT" "$SANDBOX"
		exit
	fi
	echo "The data is a symlink..."
fi

echo "Try on $AQUA"
if [ -d "$AQUA" ]; then
	echo "Data found on $AQUA"
	if [ ! -h "$AQUA" ]; then
		cp -R "$AQUA" "$SANDBOX"
		exit
	fi
	echo "But it was symlink..."
fi

echo "Try on $AZURE"
if [ -d "$AZURE" ]; then
	echo "Data found on $AZURE"
	echo "This mean you touched the directory... but this is the last chance to recover"
	if [ ! -h "$AZURE" ]; then
		cp -R "$AZURE" "$SANDBOX"
		exit
	fi
	echo "But it was a symlink too..."
fi

echo "NO DATA FOUND! YOUR DATA WILL BE RESET NEXT TIME"
