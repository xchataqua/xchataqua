#!/bin/bash
version=`git describe --tags`
version=${version#appstore-}
cd '../build/Release'
nm 'XChat Azure.app/Contents/MacOS/XChat Azure' | grep NSJSONSerialization

