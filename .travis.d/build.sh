#!/bin/bash

if [[ "$TRAVIS_OS_NAME" == "Linux" ]]; then
  swift build -c release
  swift build -c debug
else
  env
  xcodebuild
  swift build -c release
  swift build -c debug
fi
