# Architecture and research

## Objective

A macOS menu bar icon that requests a Find My sound on one explicitly selected iPhone. The app must be understandable enough for a first open-source project and small enough to audit.

## Chosen design

`Menu bar → local Accessibility adapter → Apple Find My → Apple's delivery service → iPhone`

- AppKit owns the menu bar item and window lifecycle; SwiftUI renders settings.
- `AppModel` owns user-visible state and the one persisted device-name preference.
- `FindMyController` isolates synchronous Accessibility calls in an actor, away from the main UI. It permits only one operation at a time.
- `DevicePolicy` implements exact matching and validation independently of the live UI.
- The adapter targets the bundle identifier `com.apple.findmy`. It selects Devices, resolves the name uniquely among exposed rows, opens details, checks the full header name, and invokes only a recognized sound button.
- Discovery can retry for a bounded period. Sound submission itself is attempted once, because retrying an uncertain result could ring the phone repeatedly.
- Failure opens settings with a useful message. A successful Accessibility action means the request was submitted to Find My, not that sound delivery was confirmed.

## Why UI automation

Research did not identify a documented public Apple API for a third-party Mac app to ring a user's iPhone through the Mac's existing account session. Apple's public Find My developer program concerns Find My accessories. The existing [Find My Devices Raycast project](https://github.com/Visual-Studio-Coder/find-my-devices-raycast) uses a separate local iCloud session and unofficial web endpoints; this project deliberately avoids that architecture.

Apple documents [UI automation through Accessibility](https://developer.apple.com/library/archive/documentation/LanguagesUtilities/Conceptual/MacAutomationScriptingGuide/AutomatetheUserInterface.html). The implementation uses the public AXUIElement APIs directly rather than invoking AppleScript or a shell at runtime. Find My's particular hierarchy and labels remain undocumented implementation details, so compatibility is provisional.

## Observed interface, October 11, 2026

On the development Mac (macOS 27.0.1, English), Find My exposed a Devices tab, list rows identified with `ListEntityRow`, device details as a sheet, a `PrimaryLabel` name group, and a `FMPlatterButton` with `Play Sound,Off`. A selected device can expose an `Open Details` action. Exact details may differ between versions or while content loads.

No private UI snapshots or account/device data are kept in this repository. Test fixtures use invented examples.

## Deliberate limits

- English interface only in the initial adapter.
- A unique device name without commas is required; account-wide device identifiers are not read.
- Find My may come to the foreground. Truly invisible, instant Watch-style behavior is not promised.
- Internet availability and sound delivery belong to Find My. This is not a Bluetooth or offline protocol implementation.
- No public API stability guarantee, App Store acceptance claim, or universal macOS compatibility claim.
- No background polling of devices, analytics, server, updater, account login, private framework, or broad cache access.
- macOS 27 names the permission page **Device Control and Data Access**; older versions call it **Accessibility**. The permission is broader than our feature.

## Sources

- [Apple: Play a sound in Find My on Mac](https://support.apple.com/en-ca/guide/findmy-mac/fmm48b093e33/mac)
- [Apple: Find My developer program](https://developer.apple.com/find-my/)
- [Apple: AXUIElement](https://developer.apple.com/documentation/applicationservices/axuielement)
- [Apple: NSStatusItem](https://developer.apple.com/documentation/appkit/nsstatusitem)
- [Apple: Automating the User Interface](https://developer.apple.com/library/archive/documentation/LanguagesUtilities/Conceptual/MacAutomationScriptingGuide/AutomatetheUserInterface.html)
