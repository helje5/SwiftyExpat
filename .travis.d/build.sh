#!/bin/bash

if [[ "$TRAVIS_OS_NAME" == "Linux" ]]; then
  swift build -c release
  swift build -c debug
elif [[ "$TRAVIS_OSX_IMAGE" == "xcode7.3" ]]; then
  xcodebuild
else
  xcodebuild
  swift build -c release
  swift build -c debug
fi
