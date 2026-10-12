# Privacy

## What PhonePing does

PhonePing launches Apple's signed-in Find My app and queries its macOS Accessibility interface. It identifies the Devices tab, looks for the saved exact device name, opens that device’s details, verifies the full name again, and presses the specific Play Sound control.

The app can temporarily encounter device names and status labels in memory. A Find My list label may include a location or battery status. PhonePing extracts the name and discards the suffix. It skips map-image descendants. It does not save or log accessibility trees, location data, screenshots, or device history.

During an explicit Refresh or Play Sound operation, PhonePing may launch Find My without requesting activation or unhide its window. It observes Find My activation only for the duration of that operation, retaining a boolean flag rather than app-usage history. After Find My reports playback on the selected device, it can dismiss that device’s verified details sheet and ask a newly launched Find My to quit, or restore an initially hidden instance. Details dismissal is allowed only for the process started by this operation, with the same exact device name, Playing status, and one enabled Close control. There is at most one close action, a two-second dismissal budget, and a two-second exit check after the normal quit request; an in-flight Accessibility call may extend its budget by the native timeout. Activation is observed throughout cleanup. No force quit, foreground activation, or repeated sound action is used. It leaves pending/uncertain requests, existing visible instances, and instances activated during the request alone. This state is kept in memory only; no observer or cleanup timer remains while idle.

The only app-specific preference stored is `phoneName`, under the `local.phoneping.app` preferences domain. The name can itself be personal. Use **Clear Selection** in settings to remove the selection (it saves an empty name). macOS may separately retain ordinary window/app preferences or system crash reports.

## Optional diagnostic

**Settings → Troubleshooting → Run Diagnostic…** (Help and Privacy in build 9) inspects the controls currently exposed by an already-running Find My. It does not open Find My, switch tabs, dismiss sheets, or press controls. It runs only when requested, with a five-second discovery budget and limits on tree size and depth; the last native call may extend the budget by its timeout.

The report contains allowlisted control labels/types, counts, and whether text matches the selected name. Other text and values are omitted. Device names, identifiers, locations, account details, raw trees, and screenshots are not included. The report stays in memory and is cleared when dismissed. A small summary of the latest operation remains in memory until the next operation or app exit: whether sound was invoked, playback was observed, a new process was identified, Find My started hidden or became active, and the fixed cleanup result. It contains no names, locations, UI text, paths, process IDs, or timestamps. A later diagnostic can display it without repeating a request. It is not logged, saved, copied, or sent automatically. Selecting and copying report text is a separate user action.

## Network and accounts

PhonePing contains no network request code, telemetry SDK, remote configuration, background server, or updater. It does not request Apple credentials or inspect authentication material. Find My remains responsible for authentication, network requests, device authorization, sound delivery, and any account notifications Apple sends.

“Runs locally” does not mean “offline” or “zero risk.” The Find My app still communicates with Apple, and Accessibility permission is broader than this single feature.

## Permission boundaries

Accessibility allows UI inspection and control across apps. macOS cannot scope this permission to Find My alone. PhonePing voluntarily restricts its implementation to `com.apple.findmy`; its own settings link opens System Settings. Grant permission only to code you trust.

No screen recording, input monitoring, full disk access, root access, Apple Events, or account-token access is required. The app is not App Sandbox enabled because it needs cross-app Accessibility control. Local builds use hardened runtime and an ad-hoc signature.

Maintainer-only release scripts can sign the app and upload its binary to Apple for notarization using a Keychain profile. They are never bundled into or run by PhonePing. The optional developer performance script reads process counters locally. Neither adds network or diagnostic collection to the app.

## Removal

Quit PhonePing, revoke its Accessibility permission in System Settings, and delete the app. Use **Clear Selection** first to clear the saved phone name. Developers can remove the entire app preference domain with `defaults delete local.phoneping.app`. This does not affect Find My, your Apple Account, or your iPhone.

## Sharing reports

Never publish Apple credentials, device IDs, account emails, precise locations, or raw Find My screenshots. Use fictional device names in test fixtures. An optional AI code review should receive source code and synthetic examples only, never personal device data.
