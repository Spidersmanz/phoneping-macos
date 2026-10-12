# Architecture and research

## Objective

A macOS menu bar icon that requests a Find My sound on one explicitly selected iPhone. The app must be understandable enough for a first open-source project and small enough to audit.

## Chosen design

`Menu bar → local Accessibility adapter → Apple Find My → Apple's delivery service → iPhone`

- AppKit owns a persistent standard menu and window lifecycle; SwiftUI renders grouped settings using system colors and controls. Clicking the status item opens the menu. Only choosing Play Sound submits a request. Menu opening checks permission but never discovers devices or launches Find My.
- `AppModel` owns user-visible state and the one persisted device-name preference. Short status titles appear in the menu; settings shows the full explanation. Permission recovery clears obsolete permission errors.
- `FindMyController` is the native specialization of the generic `FindMyAutomation` actor. `FindMyAccess` separates macOS calls from navigation; tests inject a synthetic tree and clock into the same navigation code used by the app. It permits only one operation at a time. `NativeFindMyAccess` maps read failures explicitly: an unsupported optional attribute is absent, a stale element is transient, and denied access is a permission failure. Unreadable device labels are never silently dropped.
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
- Build 8 requests cold launch with `activates = false` and `hides = false`, and unhides existing hidden instances. Its window may appear behind the foreground app. A bounded two-second wait lets an asynchronous unhide finish. No activation, raise, minimization, or focus-restoration fallback is used. One cold-launch request in build 9 preserved the foreground app and exited the temporary Find My process; other window states remain live checks. This is not a promise of completely invisible or instant behavior.
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

Build 9 retains one typed in-memory session summary with boolean state and a fixed cleanup reason. It distinguishes a pending request, existing/user-activated instance, unverified launch ownership, and a normal quit/hide request that was accepted or declined. The existing read-only diagnostic displays this summary even if Find My has exited. It never replays cleanup or sound, logs arbitrary error text, or persists the summary. A quit request is not presented as proof that the process exited.


## Build 11 cleanup

The build 10 quit API reported successful request delivery while Find My remained running. During follow-up inspection, the device-details sheet was dismissed and normal keyboard Quit then exited the process. This made modal details a candidate explanation. Build 11 subsequently observed playback and confirmed process exit without activation in one cold-launch test; the maintainer confirmed continued ringing and foreground preservation. Other window states and repeated cleanup remain unverified.

`FindMyQuitPreparation` uses the existing Accessibility boundary to dismiss only a verified playing-device sheet, with a two-second budget and one Close action. It verifies the full target name, current Playing status, a unique enabled Close button, and supported window structure. Unknown dialogs, missing window trees, conflicting names, cancellation, or lost ownership/activation eligibility stop cleanup. It never invokes Play Sound or changes focus.

`FindMySession.finish` now awaits preparation and a bounded normal-quit exit check. The activation observer remains installed throughout cleanup and is removed on every exit path. A reentrant finish cannot send another quit. The diagnostic distinguishes confirmed exit, an unconfirmed quit request, declined quit, and unsafe details. The selected name is passed through cleanup only for this operation and is not added to the saved diagnostic.

See [CLEANUP-FIX.md](CLEANUP-FIX.md) for tests and live evidence.
