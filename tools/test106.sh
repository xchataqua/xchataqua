#!/bin/bash
version=`git describe --tags`
cd '../build/Release'
nm 'XChat Azure.app/Contents/MacOS/XChat Azure' | grep NSJSONSerialization

