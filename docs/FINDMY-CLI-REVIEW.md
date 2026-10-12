# Find My CLI review and next release checks

This is a historical research record. Build 12 now includes the reviewed source fixes and selected icon; see [Testing](TESTING.md) for current live evidence and [Publishing](PUBLISHING.md) for the source-release checklist.

October 12, 2026. This review covers the related project's documentation and selected source, plus PhonePing's current source. It is not an independent audit. The installed PhonePing 0.1.3 build 11 was not replaced.

## Name

Keep **PhonePing** as the working name, as the maintainer requested. It is short and describes the action. An existing [PhonePing: Clap Alert](https://apps.apple.com/us/app/phoneping-clap-alert/id6761522571) app operates in the phone-finding category, so the name is not unique. Decide how to handle that overlap before public distribution. This search does not establish trademark availability.

If a different public name becomes necessary, **Lanza Ping** is the clearest company-linked alternative; **NearChime** is another candidate. A bounded exact-name search did not surface a relevant app for either, which is not clearance or proof of availability. Avoid renaming the local app repeatedly while its permission identity is still ad-hoc signed. A descriptive repository name such as `ping-iphone-mac` can remain separate from the app display name.

## What to learn from findmy-cli

The [findmy-cli README](https://github.com/omarshahine/findmy-cli#readme) documents deliberate confirmation before ringing, saved device aliases, locale handling, and Homebrew installation. Its broader feature set also uses screenshots/OCR and can keep a local location ledger. These are useful comparison points, not a reason to expand PhonePing's data access.

| Lesson | PhonePing decision |
| --- | --- |
| Make the sound action deliberate. | Keep click → menu → Play Sound, with the target visible. A second confirmation dialog for every ring adds little after an explicit named action. |
| Fail clearly when the interface cannot be understood. | Keep precise recovery text and reject incomplete lists. Add a verified already-playing result rather than reporting an unavailable control. |
| Treat language support as adapter behavior. | Add each language only with reviewed labels, synthetic fixtures, and live evidence. Keep the current English-only limit explicit. |
| Make installation discoverable. | Keep a signed DMG as the main route. Consider a Homebrew cask after stable signed releases exist. |
| Support a remembered target. | The existing selected-device preference already covers the menu app's equivalent need. More aliases are unnecessary now. |

The selected [navigation source](https://github.com/omarshahine/findmy-cli/blob/main/internal/findmy/findmy.go) reinforces checking preparation failures and sidebar state before interpreting results. PhonePing uses Accessibility elements, exact names, and bounded inspections. It will continue without screen capture, a history database, periodic device polling, or a helper runtime. No code from findmy-cli was copied, installed, or executed during this review.

## Fixed in PhonePing source

### Existing playback

Previously, an exact `Play Sound,Playing…` state fell through to an unavailable-action error. PhonePing now returns **Sound already playing** after verifying the unique selected row, full details name, and one recognized sound control. It does not press the sound button or claim to have sent another request. Conflicting controls, a different device name, and unrecognized states still fail safely.

The session report distinguishes observing playback from attempting a sound invocation. A temporary Find My process may be cleaned up only through the existing verified-details and activation checks. Existing or user-activated sessions remain protected. This state reflects what Find My reports; it is not a microphone confirmation that the phone was heard.

### Dismissing prior details

Preparation previously could send Close 16 times if dismissal was ignored, and it did not check whether Close was enabled. It now requires a recognized device-details sheet, a nonempty unambiguous header, one recognized sound control, and one enabled Close button supporting the expected action. It attempts Close once, including when the action throws. Unexpected dialogs stop the operation. These checks add no idle work, saved data, network calls, permissions, or runtime dependencies.

## Validation

Four initial regression tests reproduced the old failures. After the fixes, all **120 Swift tests** pass: 12 policy, 16 model/menu, 54 adapter/diagnostic, 12 quit-preparation, and 26 session-lifecycle tests. Release compilation passes. The privacy scanner and its 12 regression tests also pass; the changed source and text were reviewed for personal data.

These are source-level and synthetic results. The fixes have not been packaged, installed, or tested against live Find My. Build 11 remains the app with confirmed cold-launch ringing, foreground preservation, and cleanup. Bundle the source changes into one later preview and perform live validation together, avoiding a permission refresh for each small edit.

## Remaining work

| Before a public download | What establishes completion |
| --- | --- |
| Target identity and layout | Long lists, off-screen duplicates, and changed/partial details cannot select the wrong device. Unsupported layouts remain unavailable. |
| Window lifecycle | Test existing-visible, hidden, minimized, and closed-window sessions; activation during a request; full-screen/Spaces; and repeated cleanup. |
| Delivery and recovery | Check already-playing, offline/pending, permission revocation, and uncertain submissions on the packaged build. Never retry a submitted action automatically. |
| Accessibility | Complete keyboard and VoiceOver setup, target selection, status, and recovery checks. |
| Resource use | Compare fresh-launch and post-request idle on the same build, then measure Find My's active cost and repeated-use recovery. The recorded post-request CPU/wakeup difference remains unexplained. |
| App artwork | Follow-up: editable SVG masters, a small-size variant, and native bundle artwork are implemented and checked on light/dark backgrounds. Inspect the icon in the next installed preview; the earlier generated concept is not used. |
| Signing and installation | After organization approval: inspect the Lanza Studios Inc. certificate, settle the permanent bundle identity, notarize the DMG, and verify clean installation plus two signed updates. |

Apple approval blocks signing and notarization, not local reliability or design work. Launch at login, a keyboard shortcut, and additional languages can follow the core checks. Android support and a separate Control Center control remain outside this release.

PhonePing itself has no network client or telemetry. Apple's Find My still handles network delivery, and the Accessibility permission remains broad. Keep those limits explicit in public descriptions. See [privacy](../PRIVACY.md), [manual testing](TESTING.md), [performance](PERFORMANCE.md), and [distribution](DISTRIBUTION.md).
