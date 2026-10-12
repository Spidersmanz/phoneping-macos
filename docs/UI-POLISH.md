# Settings polish

October 11, 2026. Included in local preview 0.1.3 build 10.

## Changes

- Permission setup shows the action the user can take. A saved choice can still be cleared while permission is unavailable.
- Initial discovery is called Find Devices. Later requests are called Refresh. No device is selected automatically.
- Clear Selection is a secondary text action. Play Sound remains a deliberate button press, with the full target name available to accessibility tools.
- Using PhonePing, Privacy, and Troubleshooting are separate help rows. One opens at a time; the window keeps its size and scrolls as needed.
- Empty discovery says No devices found and explains how to recover. Previously, a generic selection prompt covered that result.
- Unknown errors ask the user to check Find My before trying again. Diagnostic results can be dismissed with Escape when the check has finished.

The menu-bar flow, Find My adapter, selection safeguards, permission requirements, storage, and background behavior are unchanged. No dependencies, timers, networking, or preferences were added.

## Validation

The project passes 87 synthetic tests and release compilation. The empty-list regression test failed on the previous implementation and passed after the correction. It checks the recovery text, disabled sound action, absence of a sound call, and return to setup after Clear Selection.

A separate native preview uses fictional devices and in-memory preferences. Its permission and Open Find My actions are stubs, and its sound/diagnostic responses are simulated. Checks covered permission required/allowed, initial discovery without automatic selection, empty/duplicate lists, long names, uncertain results, disabled controls during a request, expanded help and scrolling, and diagnostic dismissal with Escape. Light and dark layouts were inspected. A saved choice could be cleared while permission was unavailable.

Full keyboard traversal, VoiceOver, and system Increase Contrast remain unverified. A tooltip or accessibility label containing the full device name is not a complete screen-reader test. This pass did not send a real sound request or extend the build 9 live evidence.

## Installed app

Build 10 was installed at the existing path after quitting PhonePing, with build 9 retained as the rollback copy. All 87 synthetic tests, release packaging, and strict signature verification passed. The saved device choice was retained. The maintainer refreshed the existing permission after the ad-hoc signature changed, and the app showed Allowed. With Find My confirmed not running, one Settings Play Sound action reported a submitted request. The local diagnostic recorded playback observed, a new process, no activation, and Normal quit requested. Find My was still running afterward and exposed controls to the read-only diagnostic. No second sound request or forced termination was sent. The maintainer confirmed the intended iPhone rang and Find My stayed behind the current window. Diagnostic dismissal with Escape passed in the installed app. The desktop tool did not establish Settings closure with Command-W or the Window menu, so those checks remain unverified.

The earlier fictional-device preview was closed. The actual app now contains the polished Settings. Signing, notarization, public naming, cleanup reliability, and the remaining [manual checks](TESTING.md) are still release work.
