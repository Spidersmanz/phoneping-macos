# Installation and releases

PhonePing is currently a source-built preview. The app has no updater, update checks, or runtime server. Release tooling is for the maintainer and is not bundled into the app.

## Local development

Run `bash scripts/build.sh`, then open `dist/PhonePing.app`. The default build targets the current architecture and uses an ad-hoc signature. The script assembles and verifies a new bundle before replacing the previous build. One previous bundle is retained at `dist/PhonePing.previous.app` for rollback. Quit the app before replacing it; do not run both copies.

Keep one installed copy at a stable path. For a source-built preview that may be the project's `dist/PhonePing.app`. A downloaded release should be moved to Applications before granting access. Updates should replace that same app after quitting it.

Ad-hoc rebuilds can lose their macOS permission association even at the same path. This occurred during local development. A consistent signing identity and bundle identifier are the intended distribution solution, but permission retention must be tested with two successive signed releases. Do not reset the entire Accessibility database, weaken signing requirements, or disable Gatekeeper as a workaround.

## Maintainer prerequisites

- The maintainer chose the personal GitHub account `Spidersmanz` as repository owner. Lanza Studios Inc. remains credited in the project; no separate company organization is required. Repository creation and publication are still pending.
- Settle the project name and permanent bundle identifier before the first public binary release. The local identifier remains `local.phoneping.app` until then.
- Obtain a Developer ID Application certificate through the maintainer's Apple Developer account. Keep its private key out of this repository.
- Configure a `notarytool` profile in macOS Keychain using Apple's documented workflow. Never paste an account password into a script, issue, PR, or chat.
- Complete the live test matrix and review the source. The current English macOS 27 adapter does not establish compatibility with other versions or Intel hardware.

No valid code-signing identity was visible on the development Mac on October 11, 2026. The maintainer submitted Apple Developer enrollment that day as an organization, Lanza Studios Inc., and is awaiting Apple approval. Once issued, inspect the certificate subject/team and final archive metadata before distribution; GitHub no-reply attribution does not hide the app signing identity. Signed distribution and permission continuity are therefore not verified.

## Build a release

Set `PHONEPING_SIGNING_IDENTITY` to the full Developer ID Application certificate name and `PHONEPING_BUNDLE_ID` to the settled identifier under a domain the maintainer controls. Then run:

```sh
bash scripts/test.sh
bash scripts/build.sh --release
```

Release mode refuses an ad-hoc identity or the provisional local identifier. It requests both arm64 and x86_64 binaries, hardened runtime, and a secure timestamp, then verifies the signature. Cross-compilation alone does not prove runtime compatibility. Preserve the same bundle identifier and signing team across updates.

## Notarize an approved build

This command uploads a copy of the built application and its disk image to **Apple's notarization service**. Keep `PHONEPING_SIGNING_IDENTITY` set to the same Developer ID Application identity used to build the app. It is separate from the local build and is never invoked automatically or from pull-request CI.

```sh
bash scripts/notarize.sh YOUR_KEYCHAIN_PROFILE_NAME
```

The script checks the signature and matching signing identity, submits an app copy, requires an Accepted result, staples and validates the ticket, and checks Gatekeeper acceptance. It then creates and signs a disk image containing the stapled app and an Applications shortcut. The image must also receive an Accepted result, pass ticket validation, and pass Gatekeeper assessment. Only after both artifacts pass does it place the versioned DMG, ZIP, and their SHA-256 checksums in `dist`. Existing outputs are never replaced. It does not publish a GitHub release. Real signing/notarization remains untested until a certificate and profile are available; local rejection paths and unsigned disk-image contents have been exercised.

For the first release, test a fresh download on a clean Mac. For the second, test replacing the installed app and retaining its permission and selected device. Publish only after those checks and maintainer approval. A notarization ticket is not an Apple endorsement or an App Store review.

## Public download preparation

The disk-image workflow is implemented, with an unsigned local preview verified by mounting it read-only, checking its payload and signature, and ejecting it. This validates packaging, not public distribution: Developer ID signing, Apple notarization, final public naming, and a clean-Mac download test remain pending. The selected transparent icon is installed in build 12 and was inspected in its running About panel.

The intended installation is to move the app into Applications, open it, and grant the documented permission. No privileged installer or automatic updater is planned. A ZIP is prepared as an alternative.

For local packaging verification only, `bash scripts/create-dmg.sh SOURCE.app OUTPUT.dmg` creates an unsigned image from an already-built app without changing that app. It includes only the app and an Applications shortcut, checks image integrity, and refuses to overwrite an existing output. This helper does not upload anything. A helper-created image is not an approved public download.

## References

- [Apple: certificate ownership and types](https://developer.apple.com/help/account/certificates/certificates-overview/)
- [Apple: distribution guidance](https://developer.apple.com/library/archive/technotes/tn2206/)
- [Apple: Developer ID](https://developer.apple.com/developer-id/)
- [Apple: code-signing requirements and updates](https://developer.apple.com/documentation/technotes/tn3127-inside-code-signing-requirements)
- [Apple: notarization workflow](https://developer.apple.com/documentation/security/customizing-the-notarization-workflow)
