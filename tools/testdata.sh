
SANDBOX=~/"Library/Containers/org.3rddev.xchatazure/Data/Library/Application Support/XChat Azure"
AZURE=~/"Library/Application Support/XChat Azure"
AQUA=~/"Library/Application Support/X-Chat Aqua"
XCHAT=~/".xchat2"

for d in "$SANDBOX" "$AZURE" "$AQUA" "$XCHAT"; do
	echo -n "$d ... "
	if [ -h "$d" ]; then
		echo "SYMLINK"
	elif [ -d "$d" ]; then
		echo "REAL"
	else
		echo "NOT EXIST"
	fi
done

