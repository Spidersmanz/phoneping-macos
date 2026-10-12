# Research follow-up and release priorities

This is a historical research record. Build 12 now includes the reviewed source fixes and selected icon; see [Testing](TESTING.md) for current live evidence and [Publishing](PUBLISHING.md) for the source-release checklist.

October 12 follow-up: the maintainer prefers keeping PhonePing as the working name. The [Find My CLI review](FINDMY-CLI-REVIEW.md) records the naming caveat, two further source fixes, 120 passing Swift tests, and current release priorities. Earlier results below remain historical evidence.

October 11, 2026. Scope: current source after build 11, its recorded live tests, Apple documentation, and related projects' published documentation. This is a bounded review, not an independent security audit or an exhaustive competitor search.

## Decision

Keep the app small: click the menu bar icon, then choose Play Sound on the named device. The next improvement should be dependable behavior across Find My's window states and a straightforward signed installation. More features would not resolve the main release risks.

Build 11 has one verified cold-launch result: the intended phone kept ringing after Find My exited, and Find My stayed behind the foreground app. Existing, hidden, minimized, and user-activated instances still need their own live checks. A successful automated test does not establish those behaviors.

## Improvement made during this review

Long device names were shortened in both the native menu title and its accessibility label. The source now retains the full target name for assistive technology while keeping the visible menu compact. A synthetic regression failed before the correction and passed afterward; it also checks selection changes and clearing the selection.

All **108 app tests** pass: 12 policy, 15 model/menu, 45 adapter/diagnostic, 12 quit-preparation, and 24 lifecycle tests. Release compilation passes. This change has not been packaged or installed; the tested build 11 remains in place. No sound request or live VoiceOver test was performed during this review.

## Before public release

| Priority | Evidence and remaining gap | Acceptance check |
| --- | --- | --- |
| Device identity | Exact names and details are verified. Detected clipping, scrolling, unreadable rows, and duplicates stop the operation. A future virtualized hierarchy could still omit a duplicate without an obvious scroll container. | Test a long list with an off-screen duplicate. Stop without ringing if the entire supported list cannot be established; leave unsupported layouts unavailable. Never choose by location availability or row order. |
| Lifecycle | One build 11 cold launch and cleanup is verified. That does not establish every existing-window configuration. | Test visible, hidden, minimized, and closed-window instances; user activation during a request; Spaces/full-screen; repeated requests; and permission revocation. Preserve a Find My session opened or used by the user. |
| Delivery feedback | Playback observation and submission are distinct. Apple can queue a request for an offline phone. | Test offline/pending and uncertain results. Do not report audible delivery from a submitted request or retry after invocation. Keep explicit Open Find My recovery. |
| Accessible operation | Full menu target text is fixed in source. Complete keyboard and VoiceOver operation remains unverified. | Navigate setup, selection, status, recovery, and Settings closure without a pointer; confirm long names and error messages are understandable with VoiceOver. |
| Installation and updates | The current local app is ad-hoc signed. Organization enrollment is pending; there is no verified public signing identity yet. | Settle name and bundle identifier, inspect the issued certificate, notarize the release, install on a clean Mac, and replace it with a second signed build while preserving permission and the selected device. |
| Resource use | Source uses event-driven idle behavior. The October 12 build 11 follow-up recorded 0.5986% of one CPU core and 36.27–37.47 MiB physical footprint over 300.005 seconds after ringing, in the same process with Settings closed. | Measure Find My's launch/active cost, immediate recovery, and recovery after repeated operations. Profile cleanup responsiveness before making broader performance claims. |

Apple documents delayed sound delivery for offline devices. Local execution describes this utility's code and storage; Apple's Find My still performs network delivery. It is not an offline or Bluetooth implementation. [Apple's Find My guide](https://support.apple.com/en-ca/guide/findmy-mac/fmm48b093e33/mac).

The existing permission is broad, and the app is not sandboxed. Restricting actions to Find My is enforced by the source, not a Find My-only macOS permission. No new credential store, network client, telemetry, or screenshot capture is justified by this plan.

## Installation and public identity

Use a signed, notarized DMG with an Applications shortcut for the main download. Users should move the app into Applications before opening it and granting permission. Keep a ZIP as an optional alternative. Follow-up: local disk-image tooling is now implemented and a preview payload was verified. The release workflow stages both DMG and ZIP, but real signing/notarization remains untested pending the certificate. An original app icon is also missing from the bundle resources and should follow the final naming decision. A privileged installer is unnecessary for the intended installation. [Apple's distribution guidance](https://developer.apple.com/library/archive/technotes/tn2206/) and [notarization workflow](https://developer.apple.com/documentation/security/customizing-the-notarization-workflow).

The maintainer confirmed enrollment as **Lanza Studios Inc.**, an organization. Keep repository attribution under **Spidersmanz** and the verified GitHub no-reply identity. The app's signing identity is a separate public surface: inspect the actual certificate subject/team and final archive metadata once issued. A no-reply Git email cannot anonymize a signing certificate. [Apple's certificate overview](https://developer.apple.com/help/account/certificates/certificates-overview/).

Stable signing and app identity are the appropriate update direction; permission retention still requires testing rather than a promise. macOS uses code identity when remembering privacy grants. Never weaken signing or reset the entire permission database to avoid a development rebuild prompt. [Apple's code-signing requirements](https://developer.apple.com/documentation/technotes/tn3127-inside-code-signing-requirements).

## Related work and naming

Related open-source tools exist. Their READMEs were inspected; they were not installed or independently audited, and no implementation was copied during this review.

| Project | Documented approach | Relevant distinction |
| --- | --- | --- |
| [findmy-cli](https://github.com/omarshahine/findmy-cli) | Play Sound through Find My UI automation, with Accessibility and Screen Recording permissions, screenshots/OCR, and additional location features. | This app is a focused native menu utility whose adapter reads Accessibility elements without capturing the screen. |
| [Find My Devices for Raycast](https://github.com/Visual-Studio-Coder/find-my-devices-raycast) | Raycast plus a Python helper, separate Apple Account login, and a retained local web session. | This app reuses the Mac's existing Find My session and has no second login or external runtime. That difference does not establish that the other project is unsafe. |

Apple's public Find My developer material concerns accessories. This bounded research did not find a documented API for a third-party Mac utility to ring an iPhone through the existing Mac session. That is a search conclusion, not proof that no other integration is possible. The current UI hierarchy remains an undocumented compatibility dependency. [Apple's Find My developer program](https://developer.apple.com/find-my/).

**PhonePing is already used in the phone-finding category** by [PhonePing: Clap Alert](https://apps.apple.com/us/app/phoneping-clap-alert/id6761522571). Choose a distinct public app name before signing or publishing. The descriptive repository name `ping-iphone-mac` remains a reasonable proposal; it is not confirmed reserved or legally cleared. Keep the current local app name stable until the maintainer chooses the final identity.

Avoid “first,” “only,” or “best” claims. The defensible value is a small, inspectable menu action with no separate login, companion app, screen capture, or developer server.

## Small additions after the release checks

1. **Open at Login**, explicitly enabled by the user and off by default. Apple's `SMAppService.mainApp` supports registration of the main app without adding a helper. Reflect actual system status and launch quietly; never ring automatically. [Apple's Service Management guidance](https://developer.apple.com/documentation/servicemanagement/updating-helper-executables-from-earlier-versions-of-macos).
2. **An optional keyboard shortcut**, routed through the same selection, permission, concurrency, and single-submission checks. Choose its implementation only after evaluating conflicts and permission needs.
3. **More precise recovery text**, only when supported by actual Find My state. Investigate a verified “already playing” response and a recognized empty-device state; do not infer either from loading, a missing control, or an incomplete tree.

Keep the normal click-to-menu flow, explicit sound action, and accessible target name. Apple's menu-bar guidance supports quick access to common actions while an app is inactive; it does not require replacing the existing AppKit implementation. [Apple's MenuBarExtra documentation](https://developer.apple.com/documentation/swiftui/menubarextra).

Do not add periodic device refresh, a location dashboard, an automatic updater, or another runtime to support these conveniences. Event-driven idle behavior follows Apple's energy guidance. Cleanup currently contains bounded Accessibility reads on the main actor; profiling should establish whether those calls cause visible stalls before changing their execution model. This is an inspection concern, not a measured performance defect. [Apple's energy guidance](https://developer.apple.com/library/archive/documentation/Performance/Conceptual/power_efficiency_guidelines_osx/Timers.html).

The [manual test matrix](TESTING.md), [distribution guide](DISTRIBUTION.md), and [repository privacy checks](REPO-PRIVACY.md) remain the detailed release records. Publishing source and releasing a signed download are separate decisions.
