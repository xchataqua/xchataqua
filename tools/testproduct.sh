#!/bin/bash
version=`git describe --tags`
installer -pkg "../build/Release/XChat Azure $version.pkg" -target '/'