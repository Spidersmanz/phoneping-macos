# Independent review brief

Review the exact source commit provided by the maintainer before the first signed download. Claude review is deferred until the maintainer has access again. This document is a prepared brief, not evidence that a review has happened.

## Scope

PhonePing is a native Mac menu bar utility that presses Play Sound in Apple's Find My through Accessibility. The intended repository is `Spidersmanz/phoneping-macos`. Read [AGENTS.md](../AGENTS.md), [Privacy](../PRIVACY.md), and [Testing](TESTING.md) first.

Review source and synthetic fixtures only. Do not request account credentials, local preferences, real device labels, screenshots, raw Accessibility trees, signing keys, or a whole-workspace archive. Do not send a live sound request, change macOS permissions, merge a PR, or publish a release as part of code review.

## Questions to answer

1. Can a duplicate, renamed, partial, stale, or virtualized device list cause the wrong device to be selected? Check list completeness and the exact details verification immediately before the sound action.
2. Can an error, cancellation, timeout, or concurrent request send a sound twice or press an unrelated control? Review the boundaries between preparation, submission, playback observation, and cleanup.
3. Can cleanup close or hide an instance the user opened or activated? Review ownership checks and activation races. A normal quit request is not proof of process exit.
4. Can private text escape into preferences beyond the selected name, diagnostics, logs, fixtures, source, build artifacts, commit metadata, or publishing output? Review both app code and the local publication guard.
5. Does idle behavior avoid polling and lingering observers? Are active Accessibility calls bounded, and could main-actor cleanup block the menu? Distinguish measured issues from hypotheses.
6. Are failures understandable and recoverable without extra permissions, private APIs, or disabling macOS protections? Check keyboard labels and whether status claims match the available evidence.
7. Are CI and release scripts safe for untrusted pull requests? Keep signing credentials out of hosted PR jobs, and keep notarization separate from local builds.

## Evidence already available

The reviewed source has 120 passing Swift tests and 23 privacy regression tests, plus a clean-copy release build and strict ad-hoc signature verification. Build 12 has confirmed cold-launch ringing, background operation, and temporary-instance cleanup. A controlled existing-visible test also rang the phone, stayed behind the foreground app, and preserved the existing window. An earlier test brought Find My forward; the exact cause remains unproven.

Those results cover specific cases on one development Mac. Hidden/minimized windows, Spaces/full-screen, long or virtualized lists, offline/pending requests, already-playing state, full keyboard/VoiceOver use, and repeated-use resource recovery still have live-validation gaps. Apple organization approval, Developer ID signing, notarization, clean installation, and signed-update permission continuity are pending.

## Requested output

Start with actionable findings, ordered by severity. Include a file and line, a concrete failure scenario, its user impact, and the smallest defensible correction. Separate reproduced failures from plausible concerns and unsupported claims. Suggest a targeted regression or live check for each behavioral change. If no actionable defect is found, say so and retain the unverified scenarios above.

The maintainer decides whether to merge or publish. An assistant's review is additional evidence, not an independent security certification.
