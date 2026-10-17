# Architecture and research

## Objective

A macOS menu bar icon that requests a Find My sound on one explicitly selected iPhone. The app must be understandable enough for a first open-source project and small enough to audit.

## Chosen design

`Menu bar → local Accessibility adapter → Apple Find My → Apple's delivery service → iPhone`

- AppKit owns a persistent standard menu and window lifecycle; SwiftUI renders grouped settings using system colors and controls. Clicking the status item opens the menu. Only choosing Play Sound submits a request. Menu opening checks permission but never discovers devices or launches Find My.
- `AppModel` owns user-visible state and the one persisted device-name preference. Short status titles appear in the menu; settings shows the full explanation. Permission recovery clears obsolete permission errors.
- `FindMyController` is the native specialization of the generic `FindMyAutomation` actor. `FindMyAccess` separates macOS calls from navigation; tests inject a synthetic tree and clock into the same navigation code used by the app. It permits only one operation at a time. `NativeFindMyAccess` maps read failures explicitly: an unsupported optional attribute is absent, a stale element is transient, and denied access is a permission failure. Unreadable device labels are never silently dropped. macOS applies an Accessibility messaging timeout only to the reference it is set on, so every element read through the adapter carries its application element's timeout: one second for operations, 0.25 seconds for the diagnostic and cleanup.
- `DevicePolicy` implements exact matching and validation independently of the live UI.
- The adapter targets the bundle identifier `com.apple.findmy`. It selects Devices, resolves the name uniquely among exposed rows, opens details, checks the full header name, and invokes only a recognized sound button.
- Find My can remove its device rows and tab from Accessibility while a modal details sheet is open. After selecting a uniquely verified row, the adapter follows that sheet and verifies its full name. If device rows or the Devices tab remain exposed, it revalidates the list before submission; a partial list is not accepted. When the list is hidden, the uniqueness check is the one performed before opening details. The app does not claim to detect concurrent renames or additions hidden by that modal view.
- Recoverable discovery failures use fresh references within a ten-second monotonic budget checked between bounded Accessibility calls. This budget can be exceeded by the last in-flight call; it is not a delivery deadline. Unknown sheets and multiple detail contexts are rejected. Discovery can retry for a bounded period. Sound submission itself is attempted once, because retrying an uncertain result could ring the phone repeatedly.
- Missing setup opens settings. Operational failures update the menu bar and settings state without stealing focus; the user can explicitly open Find My. A successful Accessibility action means the request was submitted to Find My, not that sound delivery was confirmed.
- `FindMySession` scopes launch and cleanup to one explicit operation. It retains only Find My’s process reference and lifecycle flags, and observes Find My activation until that operation ends. A five-second, read-only post-submission check requires the same full device name and exact `Play Sound,Playing…` control description before cleanup. No action is retried. A submitted or uncertain request without this status leaves Find My running. After playback confirmation, or an error before submission, a newly launched process can receive a normal quit request; an initially hidden process can be hidden again. Existing visible processes and any process activated during the operation are left alone. Unknown or older launch dates never authorize quitting. Observers are removed on every exit path; normal quit/hide requests may be declined by macOS.
- The optional diagnostic uses the same Accessibility boundary but a separate read-only traversal. It never calls `prepare()` or any action method and only inspects an already-running app. It reports fixed vocabulary, counts, and equality results, with unknown values omitted. Reports remain in memory until the sheet is dismissed; no diagnostic runs on launch, menu opening, or a sound failure. Synthetic tests cover these boundaries.

## Why UI automation

Research did not identify a documented public Apple API for a third-party Mac app to ring a user's iPhone through the Mac's existing account session. Apple's public Find My developer program concerns Find My accessories. The existing [Find My Devices Raycast project](https://github.com/Visual-Studio-Coder/find-my-devices-raycast) uses a separate local iCloud session and unofficial web endpoints; this project deliberately avoids that architecture.

Apple documents [UI automation through Accessibility](https://developer.apple.com/library/archive/documentation/LanguagesUtilities/Conceptual/MacAutomationScriptingGuide/AutomatetheUserInterface.html). The implementation uses the public AXUIElement APIs directly rather than invoking AppleScript or a shell at runtime. Find My's particular hierarchy and labels remain undocumented implementation details, so compatibility is provisional.

The existing [findmy-cli project](https://github.com/omarshahine/findmy-cli) also documents a Play Sound command through Find My UI automation, using screenshots and OCR. This is related work rather than a novel integration technique. See [RESEARCH.md](RESEARCH.md) for the comparison and naming recommendation.

## Observed interface, October 11, 2026

On the development Mac (macOS 27.0.1, English), Find My exposed a Devices tab, list rows identified with `ListEntityRow`, device details as a sheet, a `PrimaryLabel` name group, and a `FMPlatterButton` with `Play Sound,Off`. A selected device can expose an `Open Details` action. Exact details may differ between versions or while content loads.

The build 6 read-only diagnostic confirmed a details sheet with a matching name, `Play Sound,Off` as the actual description, and an enabled boolean. It exposed no device rows or Devices tab while that sheet was open. This identified why the old adapter kept retrying the list and never reached the sound control.

No private UI snapshots or account/device data are kept in this repository. Test fixtures use invented examples.

## Deliberate limits

- English interface only in the initial adapter.
- The initial adapter supports the inspected expanded device panel. It rejects detected scrolling containers, missing/invalid bounds, rows outside the panel, and a panel outside its window. These guards reduce incomplete-list risk but do not prove that a future custom/virtualized Find My hierarchy exposes every device. Long-list and off-screen duplicate live tests remain a release gate; no automatic scrolling or row-index identity is used.
- A unique device name without commas is required; account-wide device identifiers are not read.
- The current source is the restored build 12 baseline plus the build 13 unhide correction. Cold launch uses `activates = false` and `hides = false`; its window may appear behind the foreground app. An existing hidden instance receives one unhide request. Its return value no longer stops the request; actual visibility is checked throughout the two-second wait, including after the last wait. Whether this resolves the first-request failure after Command-H has not yet been checked live with this source. No activation, raise, minimization, or focus-restoration fallback is used. The window-state experiments below are withdrawn and absent from the current runtime source. This is not a promise of completely invisible or instant behavior.
- Internet availability and sound delivery belong to Find My. This is not a Bluetooth or offline protocol implementation.
- No public API stability guarantee, App Store acceptance claim, or universal macOS compatibility claim.
- No background polling of devices, analytics, server, updater, account login, private framework, or broad cache access.
- macOS 27 names the permission page **Device Control and Data Access**; older versions call it **Accessibility**. The permission is broader than our feature.

## Sources

- [Apple: Play a sound in Find My on Mac](https://support.apple.com/en-ca/guide/findmy-mac/fmm48b093e33/mac)
- [Apple: Find My developer program](https://developer.apple.com/find-my/)
- [Apple: AXUIElement](https://developer.apple.com/documentation/applicationservices/axuielement)
- [Apple: background launch activation](https://developer.apple.com/documentation/appkit/nsworkspace/openconfiguration/activates)
- [Apple: hidden launch](https://developer.apple.com/documentation/appkit/nsworkspace/openconfiguration/hides)
- [Apple: NSStatusItem](https://developer.apple.com/documentation/appkit/nsstatusitem)
- [Apple: Automating the User Interface](https://developer.apple.com/library/archive/documentation/LanguagesUtilities/Conceptual/MacAutomationScriptingGuide/AutomatetheUserInterface.html)


## Background-navigation follow-up, build 7

The visible-window request succeeded and the maintainer heard the intended iPhone. The hidden-window attempt stopped before submission; the subsequent diagnostic exposed a matching row but no details view. This is evidence of a navigation-state difference, not proof that hidden operation can never work.

The next bounded investigation should distinguish a hidden application from a visible window behind the user's current app. Apple's [NSWorkspace activation option](https://developer.apple.com/documentation/appkit/nsworkspace/openconfiguration/activates) controls foreground activation separately from its [hidden-launch option](https://developer.apple.com/documentation/appkit/nsworkspace/openconfiguration/hides). [NSRunningApplication.unhide](https://developer.apple.com/documentation/appkit/nsrunningapplication/unhide()) requests that another app become visible, but its documentation does not establish the foreground/window behavior needed here. Test that behavior before changing the sound path. Apple's [NSApplication.unhideWithoutActivation](https://developer.apple.com/documentation/appkit/nsapplication/unhidewithoutactivation()) applies to the receiving application itself; PhonePing cannot simply call it on Find My through NSApplication.

Any candidate must preserve the foreground app, handle cold launch and already-hidden states, retain the existing identity checks and one-submission rule, and avoid hiding a window the user opens during the operation. Do not claim invisible operation based on a nonactivating launch request alone. Until those checks pass, keep explicit Open Find My recovery. No application behavior changed during this investigation.


### Local cleanup evidence

Build 9 retains one typed in-memory session summary with boolean state and a fixed cleanup reason. It distinguishes a pending request, existing/user-activated instance, unverified launch ownership, and a normal quit/hide request that was accepted or declined. The existing read-only diagnostic displays this summary even if Find My has exited. It never replays cleanup or sound, logs arbitrary error text, or persists the summary. A quit request is not presented as proof that the process exited. Build 12 does not retain an early preparation-failure report; the follow-up reporting experiments below were withdrawn with builds 13–16.


## Build 11 cleanup

The build 10 quit API reported successful request delivery while Find My remained running. During follow-up inspection, the device-details sheet was dismissed and normal keyboard Quit then exited the process. This made modal details a candidate explanation. Build 11 subsequently observed playback and confirmed process exit without activation in one cold-launch test; the maintainer confirmed continued ringing and foreground preservation. Other window states and repeated cleanup remain unverified.

`FindMyQuitPreparation` uses the existing Accessibility boundary to dismiss only a verified playing-device sheet, with a two-second budget and one Close action. It verifies the full target name, current Playing status, a unique enabled Close button, and supported window structure. Unknown dialogs, missing window trees, conflicting names, cancellation, or lost ownership/activation eligibility stop cleanup. It never invokes Play Sound or changes focus.

`FindMySession.finish` now awaits preparation and a bounded normal-quit exit check. The activation observer remains installed throughout cleanup and is removed on every exit path. A reentrant finish cannot send another quit. The diagnostic distinguishes confirmed exit, an unconfirmed quit request, declined quit, and unsafe details. The selected name is passed through cleanup only for this operation and is not added to the saved diagnostic.

See [CLEANUP-FIX.md](CLEANUP-FIX.md) for tests and live evidence.


## Withdrawn window-state experiments

Builds 13–16 were removed from the main working copy and installed app after repeated live failures. The build 13 unhide correction was later restored on its own, without its diagnostic additions. Their source and test changes are preserved outside the public repository. The following sections describe historical candidates; none of these additions is present in the restored build 12 runtime. See [Mac release checks](MAC-RELEASE-CHECKS.md) for recovery evidence.

### Build 13 hidden-state readiness

On October 13, the maintainer repeatedly reported that the first Play Sound attempt after Command-H returned “Find My couldn’t open,” while a second explicit attempt rang. A controlled build 12 test reproduced the immediate error and retained it for read-only inspection. Find My remained available with a matching row and no device-details sheet. This narrows the failure to session preparation but does not prove which early guard failed.

Build 13 sends at most one unhide request and evaluates actual visibility throughout the existing two-second wait, even if the request returns false. A still-hidden, exited, or cancelled process cannot proceed to sound. The final visibility check now runs after the last wait. This allows a completed visibility change to succeed without a second user request; it does not retry a sound action. Apple's [NSRunningApplication documentation](https://developer.apple.com/documentation/appkit/nsrunningapplication) explains that changing properties update across main run-loop turns, so the request return and current visibility must be treated separately.

The diagnostic now records the optional unhide return value and keeps preparation-failure reports after cleanup. All data remains fixed states in memory. Build 13 passes 128 tests, including a regression that fails on the previous code. A controlled hidden-state test then recorded an initially hidden existing instance and an unhide return of false, but visibility subsequently became ready and playback was observed from the first request. The maintainer heard the ring; no Find My activation was recorded. This confirms the early-return defect for that attempt. Cleanup reported Hide declined, but the maintainer then confirmed that the window disappeared again while Find My stayed behind. That observed result supports the hidden-state restoration for this attempt. The diagnostic wording in build 14 reports the Boolean return separately from final visibility instead of calling it a failed hide. No GitHub release or push was made.


### Build 14 minimized-window candidate

Build 13 failed both the maintainer’s minimized-window attempt and a controlled repeat from the Devices list. Neither attempted Play Sound. The controlled repeat recorded no Find My activation and preserved the existing process. Minimized operation is a separate condition from Command-H hiding; the build 13 hidden-state success does not establish minimized support.

`FindMyWindowState` checks for one supported `SceneWindow` exposed through `AXWindows`. If its `AXMinimized` value is true, it remembers that window reference before making one write to restore it. A two-second bounded check requires the same window to become non-minimized before device discovery proceeds. Permission loss, unsupported windows, user activation, cancellation, or a window that remains minimized stop preparation. An uncertain AX write is observed rather than repeated. No activation, raise, coordinate input, or device action is used by this helper.

After observed playback or an error before submission, an eligible existing session restores the same window’s minimized state with at most one write and a bounded read. Replaced/ambiguous windows and user-activated sessions are left alone. Pending requests retain the prepared window, following the existing cautious cleanup policy. An app launched by PhonePing follows the existing verified quit path. Window references are discarded after each operation; no observer or timer remains for idle monitoring.

The read-only diagnostic includes the window’s minimized attribute using fixed values only. The candidate passed 136 tests, but its first controlled live attempt failed. Before the request, the diagnostic showed one minimized window. After the preparation attempt it showed two non-minimized windows, and the operation reported no sound invocation, no activation, and unconfirmed restoration. The extra window persisted in a later diagnostic. This violates the helper’s single-window guard; the extra window’s identity and cause remain unknown. The maintainer's manual menu-bar repeat also failed with no invocation or activation and unconfirmed restoration. Its later diagnostic found one non-minimized window. Thus desktop automation is not required to reproduce the failure, but the exact window state during that manual transition was not captured. No release or push was made.

### Build 15 window-transition candidate

The build 14 observation loop returned immediately if the window list or expected identifier differed during a restoration, despite having a two-second observation budget. Build 15 uses that budget to wait for the original single `SceneWindow` to reappear with a readable minimized state. Transient AX read failures can settle within the same budget. Permission loss, cancellation, user activation, or a persistent mismatch still block progress; no extra window is accepted and no reference is substituted.

Cleanup likewise waits for the exact original window before making its one minimize write. Readiness and post-write confirmation share one two-second budget. Six additional tests cover temporary extra/missing windows, temporary identifiers/read errors, persistent ambiguity, interruption, replacement, and the shared cleanup deadline. The five initial regression tests failed against build 14 and pass with the candidate. The full suite passed 142 tests. The explicit diagnostic includes allowlisted window subroles/modal states and identifier equality, with unknown text omitted.

The controlled build 15 live test still failed before submission, with no activation and unconfirmed restoration. Before preparation, the one minimized `SceneWindow` had subrole `AXDialog` and was non-modal. Afterward, the diagnostic found a non-modal `AXDialog` without the expected identifier and a non-minimized `AXStandardWindow` matching `SceneWindow`. The normal Window menu listed one Find My window. These observations do not establish the extra window's purpose or whether the original AX reference survived the transition. Waiting longer did not resolve this attempt; no sound action was invoked.

### Build 16 diagnostic follow-up

Build 16 retains the same window-selection rules. It records the last preparation structure check as a fixed enum, separately from cleanup: same original window, missing reference, extra windows with the original present, or a role/identifier mismatch. Cleanup cannot overwrite that preparation evidence. It stores no raw window references in the completed report.

The explicit read-only diagnostic adds at most eight direct children per window, using fixed control labels/types and omitting unknown text. It still has the existing time and traversal limits, and no action, persistence, or upload path. Two additional tests verify preparation evidence survives cleanup and window-child text stays bounded and redacted. All 144 tests pass.

The build 16 Refresh-only reproduction retained `Extra windows; original reference still present`, no sound invocation, no activation, and unconfirmed restoration. The separate non-modal dialog had one button; its unknown title was omitted. This rules out an absent original reference for that attempt, but does not identify the dialog. A desktop-tool screen-sharing control is a hypothesis. Find My was then normally quit and confirmed not running. The subsequent manual check started a fresh process without attaching the desktop tool to Find My and also failed, according to the maintainer. No final diagnostic was collected for that attempt, so its cause remains unconfirmed. This candidate was withdrawn and build 12 restored.
