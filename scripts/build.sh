#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
mode="${1:---local}"
case "$mode" in --local|--release) ;; *) printf 'Usage: bash scripts/build.sh [--local|--release]\n' >&2; exit 2 ;; esac
identity="${PHONEPING_SIGNING_IDENTITY:--}"
bundle_id="${PHONEPING_BUNDLE_ID:-local.phoneping.app}"
architectures=(--arch "$(uname -m)")
if [[ "$mode" == --release ]]; then
  if [[ "$identity" != 'Developer ID Application: '* ]]; then
    printf 'Release requires PHONEPING_SIGNING_IDENTITY naming a Developer ID Application certificate.\n' >&2
    exit 2
  fi
  if [[ "$bundle_id" == local.* || ! "$bundle_id" =~ ^[A-Za-z0-9-]+(\.[A-Za-z0-9-]+)+$ ]]; then
    printf 'Release requires a permanent PHONEPING_BUNDLE_ID under a domain the maintainer controls.\n' >&2
    exit 2
  fi
  architectures=(--arch arm64 --arch x86_64)
fi
export CLANG_MODULE_CACHE_PATH="$PWD/.build/clang-cache"
swift build -c release --disable-sandbox -debug-info-format none "${architectures[@]}"
bin_dir="$(swift build -c release --disable-sandbox --show-bin-path "${architectures[@]}")"
mkdir -p dist
stage="$(mktemp -d "$PWD/dist/.package.XXXXXX")"
trap 'rm -rf "$stage"' EXIT
app="$stage/PhonePing.app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
cp "$bin_dir/PhonePing" "$app/Contents/MacOS/PhonePing"
cp Resources/Info.plist "$app/Contents/Info.plist"
cp Resources/AppIcon.icns "$app/Contents/Resources/AppIcon.icns"
/usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier $bundle_id" "$app/Contents/Info.plist"
sign_options=(--force --sign "$identity" --options runtime)
if [[ "$identity" != - ]]; then sign_options+=(--timestamp); fi
codesign "${sign_options[@]}" "$app"
codesign --verify --strict "$app"
if [[ "$mode" == --release ]]; then
  codesign -d --verbose=4 "$app" 2>&1 | grep -q '^Authority=Developer ID Application:'
fi
# Leave the previous verified bundle available for rollback. Never modify a live bundle in place.
if [[ -e dist/PhonePing.previous.app ]]; then rm -rf dist/PhonePing.previous.app; fi
if [[ -e dist/PhonePing.app ]]; then mv dist/PhonePing.app dist/PhonePing.previous.app; fi
mv "$app" dist/PhonePing.app
printf 'Built %s/dist/PhonePing.app (%s)\n' "$PWD" "$mode"
if [[ "$identity" == - ]]; then
  printf 'Local ad-hoc signature: macOS may require granting access again after a rebuild.\n'
fi
