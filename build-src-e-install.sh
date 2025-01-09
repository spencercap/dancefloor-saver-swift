#!/bin/bash
set -u

abort() {
  printf "%s\n" "$@"
  exit 1
}

if [ -z "${BASH_VERSION:-}" ]; then
  abort "Bash is required to interpret this script."
fi

if [[ "$(uname)" != "Darwin" ]]; then
  abort "DancefloorSaver is only supported on macOS."
fi

if ! command -v git >/dev/null; then
    abort "Install process requires Git."
fi

if ! command -v xcodebuild >/dev/null; then
    abort "Install process requires Xcode."
fi

BUILD_DIR="build"

printf 'Building %s...'
mkdir "$BUILD_DIR"
xcodebuild -project ./xcode/DancefloorSaver.xcodeproj \
 -scheme DancefloorSaver \
 -configuration Release clean archive \
 -archivePath "$BUILD_DIR/build.xcarchive" \
 CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=YES \
 SWIFT_VERSION=5.0 > "$BUILD_DIR/build.log"
printf ' Done\n'

printf 'Installing %s...'

cp -pr "$(find "$BUILD_DIR" -iname "*.saver")" "${HOME}/Library/Screen Savers"

printf ' Done\n'
