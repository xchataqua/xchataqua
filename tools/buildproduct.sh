#!/bin/bash

APP_KEY="3rd Party Mac Developer Application: YunWon Jeong"
INSTALLER_KEY="3rd Party Mac Developer Installer: YunWon Jeong"

PWD=`pwd`
version=`git describe --tags`
rm ../build/Release/*.app/Contents/Info.plist
xcodebuild -workspace '../XChatAqua.xcworkspace' -scheme 'Prebuild' -configuration 'Release' && \
xcodebuild -workspace '../XChatAqua.xcworkspace' -scheme 'XChat Azure' -configuration 'Release' && \
cd '../build/Release' && \
codesign --deep --all-architectures -fs "$APP_KEY" --entitlements "../../Mac/Azure/Entitlements.entitlements" "XChat Azure.app" && \
productbuild --component "XChat Azure.app" '/Applications' --sign "3rd Party Mac Developer Installer: YunWon Jeong" "XChat Azure $version.pkg"

