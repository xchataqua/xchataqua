#!/bin/bash
xcodebuild -project '../XChatAqua.xcodeproj' -target 'XChat Azure' -configuration 'Release'
cd '../build/Release'
productbuild --component 'XChat Azure.app' '/Applications' --sign "3rd Party Mac Developer Installer: 3rddev Inc." 'XChat Azure.pkg'

