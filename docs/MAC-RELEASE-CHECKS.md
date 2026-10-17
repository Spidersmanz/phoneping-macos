# Mac release checks

October 13, 2026. Local checks on macOS 27.0.1, Apple silicon. The installed app and runtime source have been restored to preview 0.1.3 build 12 after repeated failures in the hidden/minimized-window experiments. Builds 13–16 are withdrawn; their code and build 16 bundle are preserved outside the public repository. The dated evidence below records both successes and failures, not broader compatibility.

## Recovery to build 12

The archived build 12 executable matched a second archived copy. Its bundle signature and property list validated before installation, and its existing permission was refreshed. Runtime source, resources, and tests match the published baseline. All 120 baseline tests pass (12 core and 108 app tests). The restored app was not rebuilt or re-signed.

With Find My confirmed closed, one Settings Play Sound request recorded playback, a newly identified process, no activation, and a confirmed normal quit. The diagnostic and subsequent process inventory both found Find My no longer running. Audible confirmation for this recovery request is pending. No second sound request was sent.

Use the closed-app flow for now. Build 12 has the reproduced first-request failure after Command-H; minimized operation is unresolved.

## Post-review fixes

After an independent review, two changes were made to the build 12 source. The build 13 unhide correction is restored on its own: a false `unhide()` return no longer stops the request, and visibility is checked across the existing two-second wait, including after the last wait. Accessibility messaging timeouts now apply to every element read from Find My, not only the application element, because macOS sets them per reference. All 125 tests pass (12 core and 113 app), including five new tests; three of them failed on build 12. The release build compiles. Neither change has been checked live yet: the Command-H attempt reported on October 17 still ran a build 12 process started on October 13. Future window-state work must stay in an isolated candidate until it passes both the new scenario and the existing cold-launch/visible-session checks. A passing synthetic suite alone is not grounds to replace the working app.

## Completed locally

| Area | Result | Limit |
| --- | --- | --- |
| Automated reliability | All 120 restored baseline tests pass. The withdrawn build 16 passed 144 tests, including repeated-request, lifetime, visibility, and window-transition scenarios. | The additional experimental tests are preserved outside the current source. Synthetic results did not establish live minimized support. |
| Repeated submissions (withdrawn candidate) | Thirty explicit requests on one controller produce exactly thirty sound invocations, including uncertain and pending outcomes. Later explicit requests recover after a rejected list or interrupted observation. | No automatic retry; this does not measure real-device latency. |
| Session lifetime (withdrawn candidate) | Fifty session attempts release activation observers and finished sessions, including launch failures and pending playback. | Tests object lifetime; it is not a process memory measurement. |
| Release compilation | Both arm64 and x86_64 compiled before the build 13 unhide correction, with macOS 14 as their minimum. The withdrawn build 16 package compiled and passed strict signature verification and plist validation. The restored build 12 archive also passed signature and plist validation; it was not rebuilt. | The current toolchain emits an Intel deployment warning. Actual Intel and older macOS execution remain unverified. |
| Repository privacy | Publication guard and all 23 guard regression tests pass. New fixtures use fictional names. | A pattern scan is not an exhaustive privacy audit; manually review every publication diff. |
| Settings accessibility | A separate preview of the current Settings code exposes full target names, named controls, permission state, error text, and expanded/collapsed help state. Escape dismisses its diagnostic sheet. | In-memory preferences and fictional devices. This does not verify VoiceOver speech, announcements, or complete keyboard navigation. |
| Settings layout | Long names, duplicate warnings, permission guidance, and uncertain-request text remain usable in inspected light and high-contrast appearances. Duplicate names disable Play Sound. | App-local appearance overrides; system accessibility settings were not changed. |

The isolated Settings preview uses fictional data, does not call Find My, and is kept outside the public repository. Builds 13–16 below are historical experiments, not installed functionality.

## Live checks

Record each outcome separately. An accepted sound action is not proof that the phone rang. Do not include device names, locations, screenshots of personal Find My data, or raw UI trees in the results.

| Check | Procedure and acceptance | Status |
| --- | --- | --- |
| Build 12 menu request, October 13 | Use Play Sound once from the menu with another app in front, then allow cleanup without manually quitting either app. | The maintainer confirmed audible ringing and Find My stayed behind. Find My was absent at the post-request process check, and PhonePing retained its baseline process. No additional request or diagnostic was sent. |
| Comparable idle measurements | Restart build 12, close Settings, measure five minutes; request one sound from the menu, then measure the same process for five minutes without further interaction. | Complete: CPU 0.0007% before / 0.0008% after; footprint 12.95–12.97 / 18.86–18.94 MiB. Both intervals recorded zero package-idle and three interrupt wakeups. Find My was absent before and after the second interval. See [Performance](PERFORMANCE.md) for limits. |
| Repeat-use resources | Record several explicit requests and recovery on the same app process. Verify that memory settles and observers do not accumulate. Measure Find My separately. | Pending live measurement. |
| Build 12 hidden-state failure, October 13 | Open Devices, hide Find My with Command-H, then use Play Sound once. | The first request returned “Find My couldn’t open”; a second explicit attempt rang. A controlled single-attempt repeat reproduced the immediate error. Its read-only diagnostic still found a running app and a matching device row without details or read failures. The early lifecycle report was unavailable in build 12. Reproduced again with the same build 12 process (reported October 17): the first request failed and an immediate second request rang. |
| Build 13 hidden-state first request | Hide Find My with Command-H, return to PhonePing Settings, choose Play Sound once, then inspect the diagnostic without another request. | Playback observed and audible ringing confirmed by the maintainer. The report recorded an existing, initially hidden instance, unhide returning false, and no Find My activation. This confirms the old immediate-return check would stop despite the subsequent successful visibility change. Cleanup reported Hide declined, but the maintainer confirmed that Find My stayed behind and its window disappeared again. The request return value was not a reliable statement of final visibility. Build 14 uses explicit diagnostic wording instead of asserting that hiding failed. This was a Settings-button test, not a menu-bar repeat. |
| Build 13 minimized window | Minimize Find My, then use Play Sound once. Repeat from a Devices list with details closed to isolate the starting state. | Failed: the maintainer corrected the initial answer to no ring. The first diagnostic recorded no submission and activation during the request. The controlled repeat also failed, with no submission or activation and an existing session preserved. A matching row remained available to the diagnostic, but no details sheet opened. The build 14 result is recorded below. |
| Build 14 minimized window | After permission refresh and app restart, minimize the Devices window, confirm its starting state with the read-only diagnostic, then choose Play Sound once in Settings. | Failed before sound submission: the initial diagnostic found one minimized window; afterward it found two non-minimized windows. The operation recorded no sound invocation, no playback, no activation, and unconfirmed restoration, with “Restore the Find My window” shown. A later read-only diagnostic still found two windows. Their identity and cause are not established. The maintainer’s normal manual menu-bar attempt also failed. That report again recorded no submission, no activation, and unconfirmed restoration, but the later diagnostic found one non-minimized window. The failure does not require agent-controlled input; the exact state during the manual transition remains unknown. |
| Build 15 minimized window | Confirm one minimized window with the read-only diagnostic, choose Play Sound once, then inspect without another request. | Failed before sound submission, with no activation and unconfirmed restoration. The original minimized SceneWindow reported AXDialog/non-modal; afterward the report found a separate AXDialog without that identifier and a non-minimized AXStandardWindow matching SceneWindow. The normal Window menu listed one window. The extra window’s purpose and original-reference identity remain unresolved. |
| Build 16 diagnostic follow-up | Refresh the existing development permission; use Refresh from a minimized starting state, then inspect the diagnostic. | Reproduced without sound: extra windows remained, with the original reference still present, no activation, and unconfirmed restoration. The extra non-modal dialog contains one button; its unknown text is omitted. Find My was normally quit and confirmed not running afterward. The subsequent fresh manual launch/minimize/Refresh check also failed, according to the maintainer. Its final diagnostic was not collected, so the extra-window explanation is not established for that attempt. The maintainer then reported the app no longer working; build 16 was withdrawn and build 12 restored. |
| Post-review fixes, Command-H | Quit and reopen the rebuilt app, re-grant permission if asked, hide Find My with Command-H, then use Play Sound once. Repeat the closed-app and visible-window flows. | Pending. |
| Other window states | Start with Find My on People/Items or showing other details; check foreground preservation and existing-session preservation separately. | Pending; earlier cold-launch and existing-visible evidence is in [Testing](TESTING.md). |
| User activity during a request | Activate Find My while PhonePing is working. Leave the user's session alone afterward. | Synthetic coverage; live pending. |
| Pending/offline delivery | With the phone unavailable, verify cautious feedback and no automatic resubmission or premature cleanup. | Synthetic coverage; live pending. |
| Permission loss | Revoke access, attempt an explicit action, then restore it. Verify useful guidance and recovery without a crash. | Synthetic coverage; live pending. |
| Long device list | Include an off-screen duplicate. Refuse to act if the complete supported list cannot be established. | Release gate; synthetic clipping/scrolling rejection is not sufficient live evidence. |
| Keyboard window closure | Open Settings and press Command-W; leave the menu bar app running. | Passed on build 12, confirmed by the maintainer on October 13. Settings closed and the menu icon remained. |
| Settings keyboard focus | Try Tab and Shift-Tab with macOS Keyboard navigation enabled. | The first attempt skipped controls with the system option off. With permission to enable it temporarily, the maintainer reported navigation working. The option was then restored to off and verified in System Settings. No sound action was activated. |
| VoiceOver Settings labels | Navigate Settings with VoiceOver and listen to the device and control labels, without activating Play Sound; turn VoiceOver off afterward. | Passed as a basic listening check on build 12: the maintainer reported clear spoken labels and confirmed VoiceOver was off afterward. No recording or personal label text was collected. |
| Complete keyboard and VoiceOver flow | Reach and operate the menu, picker, help, and diagnostic dismissal without a pointer. Verify full target names, disabled actions, errors, and status changes with VoiceOver. | Basic Settings focus, window closure, and spoken labels are verified above. Exhaustive control activation, menu navigation, and spoken error/status changes remain release gates. |

Use the normal menu action for audible tests. Never send another request merely because the prior result is uncertain. Stop a test if the target cannot be established uniquely.

## After Apple enrollment

The signed download needs these additional checks:

- Inspect the issued Developer ID identity, settle the permanent bundle identifier, and sign the release candidate.
- Notarize and verify the DMG and ZIP; inspect archive contents and public identity metadata.
- Test a clean installation, first permission grant, and replacement with a second signed build at the same path.
- Verify compatibility on the macOS versions and processor architectures named in the release notes.

Follow [Distribution](DISTRIBUTION.md) for the packaging workflow. No release was created or published during this local check.
