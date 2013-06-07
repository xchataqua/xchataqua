#!/bin/bash
PWD=`pwd`
version=`git describe --tags`
version=${version#appstore-}
rm ../build/Release/*.app/Contents/Info.plist
xcodebuild -project '../XChatAqua.xcodeproj' -target 'Prebuild' -configuration 'Release' && \
xcodebuild -project '../XChatAqua.xcodeproj' -target 'XChat Azure' -configuration 'Release' && \
cd '../build/Release' && \
productbuild --component "XChat Azure.app" '/Applications' --sign "3rd Party Mac Developer Installer: 3rddev Inc." "XChat Azure $version.pkg"

echo "Release? Do not forget build REAL XPC for Growl"
cd "$PWD"
bash testxpc.sh
