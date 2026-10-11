# Privacy

## What PhonePing does

PhonePing launches Apple's signed-in Find My app and queries its macOS Accessibility interface. It identifies the Devices tab, looks for the saved exact device name, opens that device’s details, verifies the full name again, and presses the specific Play Sound control.

The app can temporarily encounter device names and status labels in memory. A Find My list label may include a location or battery status. PhonePing extracts the name and discards the suffix. It skips map-image descendants. It does not save or log accessibility trees, location data, screenshots, or device history.

The only app-specific preference stored is `phoneName`, under the `local.phoneping.app` preferences domain. The name can itself be personal. Use **Forget** in settings to remove the selection (it saves an empty name). macOS may separately retain ordinary window/app preferences or system crash reports.

## Network and accounts

PhonePing contains no network request code, telemetry SDK, remote configuration, background server, or updater. It does not request Apple credentials or inspect authentication material. Find My remains responsible for authentication, network requests, device authorization, sound delivery, and any account notifications Apple sends.

“Runs locally” does not mean “offline” or “zero risk.” The Find My app still communicates with Apple, and Accessibility permission is broader than this single feature.

## Permission boundaries

Accessibility allows UI inspection and control across apps. macOS cannot scope this permission to Find My alone. PhonePing voluntarily restricts its implementation to `com.apple.findmy`; its own settings link opens System Settings. Grant permission only to code you trust.

No screen recording, input monitoring, full disk access, root access, Apple Events, or account-token access is required. The app is not App Sandbox enabled because it needs cross-app Accessibility control. Local builds use hardened runtime and an ad-hoc signature.

## Removal

Quit PhonePing, revoke its Accessibility permission in System Settings, and delete the app. Use **Forget** first to clear the saved phone name. Developers can remove the entire app preference domain with `defaults delete local.phoneping.app`. This does not affect Find My, your Apple Account, or your iPhone.

## Sharing reports

Never publish Apple credentials, device IDs, account emails, precise locations, or raw Find My screenshots. Use fictional device names in test fixtures. An optional AI code review should receive source code and synthetic examples only, never personal device data.
