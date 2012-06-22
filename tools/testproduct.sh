#!/bin/bash
version=`git describe --tags`
version=${version#appstore-}
installer -pkg "../build/Release/XChat Azure $version.pkg" -target '/'