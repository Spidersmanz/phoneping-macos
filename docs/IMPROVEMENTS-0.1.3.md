# Preview 0.1.3 review

The five requested improvement areas are implemented in local build 9, with the remaining live checks listed below. This is a local preview; public release validation is incomplete. The later [Settings polish](UI-POLISH.md) is installed as build 10 and passes 87 tests, release packaging, and local signature verification. The maintainer confirmed its first request rang the intended iPhone while Find My stayed behind. Find My remained running after a normal quit request; cleanup reliability remains unresolved.

| Area | Implemented and checked | Remaining evidence |
| --- | --- | --- |
| Device selection | Exact unique name, full details-name verification, rejection of unreadable or detected clipped/scrolling lists; synthetic regressions pass | Long lists and off-screen duplicates in custom/virtualized layouts |
| Background behavior | Nonactivating launch, bounded unhide, no automatic sound retry, cleanup only after observed playback; one build 9 menu-bar request rang the intended phone, stayed behind, and exited its temporary Find My process | Initially hidden, existing-visible, user-activated, minimized/full-screen cases; repeated cleanup reliability |
| Installation and updates | Verified staged replacement with one rollback copy; separate Developer ID release mode; notarization and checksum tooling | Apple enrollment, certificate, notarized download, permission continuity across two signed updates |
| Performance and accessibility | No idle polling; bounded tree traversal; developer-only process counters; native light/dark Settings inspected with fictional devices | Same-session post-request and repeated-use resource measurements; full keyboard/VoiceOver and system contrast checks |
| Failure testing | 86 synthetic tests cover selection, model/menu state, Accessibility navigation, read-only diagnostics, and process lifecycle | Offline delivery, permission revocation during use, and additional supported macOS versions |

## Current live result

With Find My confirmed closed, the maintainer selected Play Sound from PhonePing's menu bar and confirmed the intended iPhone rang while Find My stayed behind. Process checks found Find My absent afterward. The read-only diagnostic recorded playback observed, a new process, no activation, and a normal quit request. It did not launch Find My or send another sound.

This verifies one cold-launch request with cleanup on macOS 27.0.1 in English. Build 8 had left Find My running after a successful background ring; the reason for that earlier result is unresolved. Neither result proves the remaining window configurations. The chronological record is in [TESTING.md](TESTING.md).

## UI and recovery

Normal click opens a standard menu with Play Sound on the selected device. Opening the menu does not discover devices or send sound. Settings, Open Find My, About, and Quit remain in the same menu; no separate Control Center entry is planned.

Settings presents permission guidance first when access is required. Refresh guidance appears only when usable; a saved selection explains on-demand verification. Help puts everyday use and privacy before troubleshooting. Uncertain results tell the user to check Find My before trying again. The About panel credits Lanza Studios Inc. and Spidersmanz.

## Validation and limits

Build 9 passes 86 synthetic tests: 12 policy, 13 model/menu, 45 adapter/diagnostic, and 16 lifecycle checks. Release compilation, packaging, and strict local signature verification pass. Tests use invented devices and do not launch Find My or ring a phone.

Find My's UI is not a stable device-identity API. Bounds and list checks reduce incomplete-list risk but cannot prove that an untested custom layout exposes every device. A long-list duplicate test remains a release gate. Availability and location never substitute for identity.

PhonePing has no network client, telemetry, account credentials, private APIs, or third-party runtime dependencies. The selected name is stored locally; temporary labels and the cleanup diagnostic remain in memory. Accessibility is broad permission, and Apple's Find My still uses its network service. See [PRIVACY.md](../PRIVACY.md).

Apple Developer enrollment is pending. Local ad-hoc updates can require re-adding permission; no security protection is disabled to avoid that. Signing, notarization, final identity, reviewed source, and maintainer approval precede public distribution.

For the resource measurements and their conditions, see [PERFORMANCE.md](PERFORMANCE.md). The [quality review](REVIEW.md), [background checks](BACKGROUND-OPERATION.md), and [release plan](ROADMAP.md) track remaining work.
