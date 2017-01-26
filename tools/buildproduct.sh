#!/bin/bash
PWD=`pwd`
version=`git describe --tags`
version=${version#appstore-}
rm ../build/Release/*.app/Contents/Info.plist
xcodebuild -workspace '../XChatAqua.xcworkspace' -scheme 'Prebuild' -configuration 'Release' && \
xcodebuild -workspace '../XChatAqua.xcworkspace' -scheme 'XChat Azure' -configuration 'Release' && \
cd '../build/Release' && \
productbuild --component "XChat Azure.app" '/Applications' --sign "3rd Party Mac Developer Installer: YunWon Jeong" "XChat Azure $version.pkg"

