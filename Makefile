all: release
	

buildnumber:
	xcodebuild -target 'GenerateBuildNumber'

sgpalette:
	xcodebuild -target 'SGPalette'

xchataqua: sgpalette
	xcodebuild -target 'X-Chat Aqua'

release:
	xcodebuild -target 'Release'
	
clean:
	xcodebuild clean
