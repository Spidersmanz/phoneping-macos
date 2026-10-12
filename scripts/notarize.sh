#!/bin/bash
# Maintainer-only: uploads the app and disk image to Apple. Never called by build or CI.
set -euo pipefail
cd "$(dirname "$0")/.."
if [[ "$#" != 1 || -z "$1" ]]; then
  printf 'Usage: bash scripts/notarize.sh KEYCHAIN_PROFILE\n' >&2; exit 2
fi
identity="${PHONEPING_SIGNING_IDENTITY:-}"
[[ "$identity" == 'Developer ID Application: '* ]] || {
  printf 'Set PHONEPING_SIGNING_IDENTITY to the release Developer ID Application certificate.\n' >&2; exit 2;
}
app="$PWD/dist/PhonePing.app"
codesign --verify --strict "$app"
signature_details="$(codesign -d --verbose=4 "$app" 2>&1)"
printf '%s\n' "$signature_details" | grep -q '^Authority=Developer ID Application:' || {
  printf 'A Developer ID signed release build is required.\n' >&2; exit 2;
}
printf '%s\n' "$signature_details" | grep -Fqx "Authority=$identity" || {
  printf 'The disk image signing identity must match the app signing identity.\n' >&2; exit 2;
}
bundle_id="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$app/Contents/Info.plist")"
[[ "$bundle_id" != local.* ]] || { printf 'Choose the permanent bundle identifier before distribution.\n' >&2; exit 2; }
version="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$app/Contents/Info.plist")"
[[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || exit 2
archive="PhonePing-$version.zip"
disk_image="PhonePing-$version.dmg"
for filename in "$archive" "$archive.sha256" "$disk_image" "$disk_image.sha256"; do
  [[ ! -e "dist/$filename" && ! -L "dist/$filename" ]] || {
    printf 'A release output already exists; choose a new version.\n' >&2; exit 2;
  }
done
stage="$(mktemp -d "$PWD/dist/.notarize.XXXXXX")"
trap 'rm -rf "$stage"' EXIT
# Notarize a copy; do not alter the locally installed build while waiting.
ditto "$app" "$stage/PhonePing.app"
ditto -c -k --keepParent "$stage/PhonePing.app" "$stage/submission.zip"
xcrun notarytool submit "$stage/submission.zip" --keychain-profile "$1" --wait --output-format plist > "$stage/result.plist"
status="$(/usr/libexec/PlistBuddy -c 'Print :status' "$stage/result.plist")"
[[ "$status" == Accepted ]] || { printf 'Notarization was not accepted. No distributable was produced.\n' >&2; exit 1; }
xcrun stapler staple "$stage/PhonePing.app"
xcrun stapler validate "$stage/PhonePing.app"
spctl --assess --type execute "$stage/PhonePing.app"
ditto -c -k --keepParent "$stage/PhonePing.app" "$stage/$archive"
bash scripts/create-dmg.sh "$stage/PhonePing.app" "$stage/$disk_image"
codesign --sign "$identity" --timestamp "$stage/$disk_image"
codesign --verify --strict "$stage/$disk_image"
xcrun notarytool submit "$stage/$disk_image" --keychain-profile "$1" --wait --output-format plist > "$stage/dmg-result.plist"
status="$(/usr/libexec/PlistBuddy -c 'Print :status' "$stage/dmg-result.plist")"
[[ "$status" == Accepted ]] || { printf 'Disk image notarization was not accepted. No distributable was produced.\n' >&2; exit 1; }
xcrun stapler staple "$stage/$disk_image"
xcrun stapler validate "$stage/$disk_image"
spctl --assess --type open --context context:primary-signature "$stage/$disk_image"
(cd "$stage" && shasum -a 256 "$archive" > "$archive.sha256" && shasum -a 256 "$disk_image" > "$disk_image.sha256")
# Keep every output staged until both artifacts have passed their checks.
for filename in "$archive" "$archive.sha256" "$disk_image" "$disk_image.sha256"; do
  [[ ! -e "dist/$filename" && ! -L "dist/$filename" ]] || {
    printf 'A release output appeared during preparation; no files will be replaced.\n' >&2; exit 2;
  }
done
for filename in "$archive" "$archive.sha256" "$disk_image" "$disk_image.sha256"; do
  ln "$stage/$filename" "dist/$filename"
done
printf 'Prepared dist/%s, dist/%s, and checksums. Nothing was published.\n' "$disk_image" "$archive"
