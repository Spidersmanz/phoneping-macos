# PhonePing 0.1.3 preview notes — draft

A small macOS menu bar utility for playing a sound on a selected iPhone through Apple's Find My. Click the icon, then choose Play Sound on the named device. An open-source project by Lanza Studios Inc., maintained by Spidersmanz; the intended GitHub owner is `Spidersmanz`.

This is a local preview under a working name. No repository or release has been published.

## Included

- Native menu and Settings with an explicit device choice, permission guidance, and clear recovery messages.
- A single guarded sound request: exact name checks, duplicate-name rejection, and no automatic retry after submission.
- Nonactivating Find My launch and conservative cleanup after observed playback.
- A local read-only diagnostic with personal text omitted, including an in-memory cleanup result in build 9.
- No app network client, telemetry, separate sign-in, companion iPhone app, or third-party runtime dependency. The selected name is saved on this Mac; Apple handles account access and network delivery.

## Build 12 icon and reliability follow-up

Build 12 is installed locally with the selected transparent graphite phone icon; the native menu bar symbol is unchanged. The running About panel shows the new icon and public credits. It also packages full device names in menu accessibility labels, informational handling of verified existing playback, and a single guarded details-dismissal attempt. All 120 Swift tests, 16 privacy regressions, release packaging, and strict signature verification pass. Build 11 is retained for rollback. After permission refresh, one cold-launch Settings request recorded playback, no activation, and confirmed normal exit. Independent process checks found Find My absent before and after the request. The maintainer confirmed the iPhone rang while Find My stayed behind the current window. This does not validate all window configurations or the existing-playback scenario.

## Build 11 cleanup

Build 11 adds verified device-details dismissal before normal quit and a bounded exit check. It passes 107 synthetic tests, packaging, and local signature verification. One cold-launch Settings request observed playback, identified a new Find My process, recorded no activation, and reported Normal quit confirmed. Independent process checks found Find My absent before and after the request. The maintainer confirmed that the iPhone kept ringing after Find My closed and that Find My stayed behind the current window. See [CLEANUP-FIX.md](CLEANUP-FIX.md).

## Earlier verification

Build 10 passed 87 synthetic tests and release compilation. Its Settings changes are now installed in build 10, with build 9 retained for rollback. Build 10 passes packaging and local signature verification. Its first request recorded playback, but Find My remained running after the normal quit request; the maintainer confirmed the intended iPhone rang and Find My stayed behind the current window. Build 9 previously passed 86 tests, release compilation, and local signature checks. In one build 9 test, the maintainer selected Play Sound from the menu bar and confirmed the intended iPhone rang while Find My stayed behind. Find My was closed before the request and exited afterward; the diagnostic recorded playback and a normal quit request. The native Settings layout was inspected with fictional device data in light and dark appearances.

## Settings in build 10

Setup now shows the next usable action, with Find Devices for the initial list and Refresh afterward. Clear Selection is less prominent, help is split into three sections, and an empty list gives a recovery step. No device-selection or Find My automation rules changed. See [UI-POLISH.md](UI-POLISH.md).

## Known limits

One cold-launch background request and cleanup passed in build 9. Build 8 previously left Find My running, so repeated-use reliability is still open. Long or virtualized lists, offline behavior, other window configurations, full keyboard/VoiceOver access, and same-session post-request performance still need validation. A five-minute build 9 idle sample with Settings closed after restart is recorded in [Performance](PERFORMANCE.md). This is an English Find My adapter observed on macOS 27.0.1; the macOS 14 deployment target is not a compatibility claim.

Accessibility access is broad. Local ad-hoc builds may need permission refreshed after an update. Developer ID signing, notarization, update-permission continuity, final naming, and public-release approval remain later gates. These notes do not announce a downloadable release.

For setup, see [README](../README.md). For evidence and outstanding checks, see [Testing](TESTING.md), [Review](REVIEW.md), and [Privacy](../PRIVACY.md).
