#!/bin/bash

if [[ "$TRAVIS_OS_NAME" == "Linux" ]]; then
  swift build -c release
  swift build -c debug
else
  env

  SWIFT_VERSION="$(${SWIFT_DRIVER} --version | head -1 | sed 's/^.*[Vv]ersion[\t ]*\([.[:digit:]]*\).*$/\1/g')"
  declare -a SWIFT_VERSION_LIST="(${SWIFT_VERSION//./ })"
  SWIFT_MAJOR=${SWIFT_VERSION_LIST[0]}
  SWIFT_MINOR=${SWIFT_VERSION_LIST[1]}
  SWIFT_SUBMINOR_OPT=${SWIFT_VERSION_LIST[2]}
  SWIFT_SUBMINOR=${SWIFT_SUBMINOR_OPT}
  if [[ "x${SWIFT_SUBMINOR}" = "x" ]]; then SWIFT_SUBMINOR=0; fi
  
  echo "SWIFT MAJOR: ${SWIFT_MAJOR}"

  xcodebuild
  
  swift build -c release
  swift build -c debug
fi
