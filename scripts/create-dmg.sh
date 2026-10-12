#!/bin/bash
# Local packaging only. Signing/notarization are handled by notarize.sh.
set -euo pipefail
if [[ "$#" != 2 || "$1" != *.app || "$2" != *.dmg ]]; then
  printf 'Usage: bash scripts/create-dmg.sh SOURCE.app OUTPUT.dmg\n' >&2; exit 2
fi
source_app="$1"
output="$2"
[[ -d "$source_app/Contents" && -f "$source_app/Contents/Info.plist" ]] || {
  printf 'A built application bundle is required.\n' >&2; exit 2;
}
[[ ! -e "$output" && ! -L "$output" ]] || {
  printf 'Output already exists; it will not be replaced.\n' >&2; exit 2;
}
codesign --verify --strict "$source_app"
mkdir -p "$(dirname "$output")"
stage="$(mktemp -d "$(dirname "$output")/.dmg.XXXXXX")"
trap 'rm -rf "$stage"' EXIT
app_name="$(basename "$source_app")"
mkdir "$stage/payload"
# The payload is deliberately limited to the app and the installation shortcut.
ditto "$source_app" "$stage/payload/$app_name"
ln -s /Applications "$stage/payload/Applications"
hdiutil create -quiet -fs HFS+ -volname "${app_name%.app}" -srcfolder "$stage/payload" -format UDZO "$stage/image.dmg"
hdiutil verify -quiet "$stage/image.dmg"
# Atomic, no-clobber publication on the same filesystem, including concurrent runs.
ln "$stage/image.dmg" "$output"
printf 'Created unsigned disk image. Use notarize.sh for a public release.\n'
