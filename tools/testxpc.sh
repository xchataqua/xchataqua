#!/bin/bash
version=`git describe --tags`
version=${version#appstore-}
cd '../build/Release'
ls XPCServices

