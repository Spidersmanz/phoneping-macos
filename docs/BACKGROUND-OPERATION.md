# Background operation, preview builds 9–11

## Build 11 cleanup check

Build 11 adds verified details dismissal before normal quit and an exit check. All 107 synthetic tests, release packaging, and local signature verification pass. One cold-launch Settings request observed playback, identified a new Find My process, recorded no activation, and reported Normal quit confirmed. Independent process checks found Find My absent before and after the request. The maintainer confirmed that the iPhone kept ringing after Find My closed and that Find My stayed behind the current window. See [CLEANUP-FIX.md](CLEANUP-FIX.md).

## Build 10 check

Build 10 was installed at the existing path after quitting PhonePing, with build 9 retained as the rollback copy. All 87 synthetic tests, release packaging, and strict signature verification passed. The saved device choice was retained. The maintainer refreshed the existing permission after the ad-hoc signature changed, and the app showed Allowed. With Find My confirmed not running, one Settings Play Sound action reported a submitted request. The local diagnostic recorded playback observed, a new process, no activation, and Normal quit requested. Find My was still running afterward and exposed controls to the read-only diagnostic. No second sound request or forced termination was sent. The maintainer confirmed the intended iPhone rang and Find My stayed behind the current window. Diagnostic dismissal with Escape passed in the installed app. The desktop tool did not establish Settings closure with Command-W or the Window menu, so those checks remain unverified.

## Intent

Keep the user’s current app in front while Find My sends the sound. Use one menu bar icon with an explicit Play Sound action. A separate Control Center feature is out of scope.

## Evidence

- Build 7’s visible-window request rang the selected iPhone, confirmed by the maintainer.
- Build 7’s hidden-window request stopped before submission; the diagnostic showed a matching row but no details view.
- In a subsequent build 7 test, Find My exposed the exact sound-control description `Play Sound,Playing…` after submission. The maintainer manually closed Find My and reported that sound continued. A process-presence check subsequently found no Find My process. This is one observed/reported case, not an offline-delivery guarantee.
- Apple documents sound lasting about two minutes when online, and queued playback after an offline device reconnects: [Play a sound in Find My](https://support.apple.com/en-ca/guide/findmy-mac/fmm48b093e33/mac).

## Implemented behavior

1. Require permission before launching or inspecting Find My.
2. Reuse a running instance or ask macOS to launch without activation and without deliberately hiding its controls. Unhide an already-hidden instance, with a bounded wait for readiness.
3. Apply the existing complete-list, unique-name, full-details-name, and exact sound-control guards.
4. Submit sound at most once. Read the same details for up to five seconds for the exact Playing status. Uncertainty never triggers a resubmission.
5. After playback confirmation, revalidate and dismiss the selected device’s details sheet for an instance started by this request. Require the sheet to disappear, then request a normal quit and check for process exit. For an initially hidden instance, restore its hidden state instead. Leave an existing visible instance alone. Any Find My activation during the operation prevents automatic cleanup, including if the user subsequently switches away.
6. Before-submission failures can clean up a temporary instance. Pending, unknown, cancelled-after-submission, and uncertain outcomes leave Find My available. No polling continues after the bounded operation ends.

The app does not minimize Find My or force-quit it. Its window may appear behind the current app. The launch/unhide calls do not establish that Find My itself never moves forward; that requires a live check. A process returned with an older or unknown launch date is never claimed for automatic quitting. A simultaneous external launch cannot be distinguished perfectly; observed activation prevents cleanup.

## Live acceptance checks

- [x] Find My initially quit: build 11 observed playback and confirmed exit after one Settings request. The maintainer confirmed the phone kept ringing after closure and Find My stayed behind. Build 9 previously completed one menu-bar request with cleanup.
- [ ] Find My initially hidden: sound is heard, foreground work stays in front, Find My returns to hidden.
- [ ] Find My already visible behind another app: sound works and its existing window is left open.
- [ ] User opens Find My during a request: automatic quit/hide is suppressed.
- [ ] Offline/pending or uncertain action: no automatic quit, hide, or resubmission.
- [ ] Window closed but process still running, minimized, multiple Spaces/full-screen, and additional supported OS versions.

Build 9 passes all 86 synthetic tests, release packaging, and strict signature verification. The installed app has permission Allowed. Synthetic lifecycle and adapter tests cover the remaining cleanup branches but do not establish their live window ordering, delivery, or OS behavior.


## Build 8 live result

The maintainer refreshed permission and PhonePing restarted with access Allowed. Find My was initially not running. One request returned successfully; the maintainer confirmed audible sound and that Find My stayed behind. Find My was still running in the subsequent process check. This verifies one background cold-launch ring, not automatic cleanup or every window configuration. The later build 9 result below completes the cold-launch acceptance item for one local test.

Build 9 adds a local last-operation summary to the read-only diagnostic so the next test can distinguish the reason cleanup was skipped or declined. It retains fixed states only, with no device names, location data, process IDs, timestamps, files, or network transmission. It does not change the existing cleanup guards or retry sound.

## Build 9 live result

After permission was refreshed, Find My was confirmed not running. The maintainer used the menu bar Play Sound action once and confirmed the intended iPhone rang while Find My stayed behind. Process checks then confirmed Find My was no longer running. The read-only diagnostic recorded playback observed, new process identified, no activation, and a normal quit request; it also confirmed there was no running Find My to inspect. It did not launch Find My or send another sound.

This verifies one cold-launch background request with cleanup on macOS 27.0.1. It does not explain the earlier build 8 outcome or prove the remaining window states. No cleanup safeguard was relaxed between those tests.
