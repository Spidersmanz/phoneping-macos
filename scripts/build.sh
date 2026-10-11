#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
export CLANG_MODULE_CACHE_PATH="$PWD/.build/clang-cache"
swift build -c release --disable-sandbox -debug-info-format none
APP="$PWD/dist/PhonePing.app"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
BIN_DIR="$(swift build -c release --disable-sandbox --show-bin-path)"
cp "$BIN_DIR/PhonePing" "$APP/Contents/MacOS/PhonePing"
cp Resources/Info.plist "$APP/Contents/Info.plist"
codesign --force --sign "${PHONEPING_SIGNING_IDENTITY:--}" --options runtime "$APP"
codesign --verify --strict "$APP"
printf 'Built %s\n' "$APP"
