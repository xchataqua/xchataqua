all: release
	

buildnumber:
	xcodebuild -target 'GenerateBuildNumber'

xchataqua:
	xcodebuild -target 'X-Chat Aqua'

sgpalette:
	xcodebuild -target 'SGPalette'

release:
	xcodebuild -target 'Release'
	
clean:
	xcodebuild clean
