# Settings and feature plan

Proposed October 11, 2026. The public name is still undecided; `ping-iphone-mac` is the proposed repository name. This document describes the target behavior. Local preview 0.1.3 uses a standard menu on click, grouped native settings, brief menu status, detailed recovery text in settings, and a standard About panel. Build 8 adds nonactivating launch and playback-aware cleanup; build 9 verified one cold-launch menu-bar request with audible delivery, foreground preservation, and process exit. Other window states and repeated use still need live validation. Login, a keyboard shortcut, the post-request cooldown, and full VoiceOver validation remain planned.

The later [Settings source follow-up](UI-POLISH.md) adds a clearer first discovery action, simpler permission setup, separate help sections, and empty-list recovery. It is now installed as build 10, after review in a separate fictional-device preview.

## Product contract

Choose one iPhone, open the Mac menu bar menu, and select Play Sound to ask Apple's Find My to play a sound. Setup should explain the permission once, preserve the user's explicit selection, and make recovery understandable. No sound should be requested on launch, login, refresh, selection changes, or permission changes.

The app runs locally and uses the Mac's existing Find My session. Apple handles authentication and sound delivery. Find My may become visible and an offline phone may ring later. No instant, invisible, offline, or confirmed-delivery promise.

## Performance requirements

Lightweight operation is a release requirement. While idle, use no app-owned repeating timers, background device scans, helper processes, animation loops, or keep-awake assertions. Check permission on activation and explicit actions; open and inspect Find My only for Refresh or Play Sound. Keep UI work responsive, use bounded discovery, and retain only the small selection/result state.

Before release, measure the release app after a warm-up with settings closed over a five-minute idle window. Record average CPU, physical memory footprint, and wakeups, plus recovery after repeated requests. An initial target is less than 0.1% average CPU on the test Mac, zero app-owned scheduled idle wakeups, and a stable memory footprint with no sustained growth across repeated runs. These are targets, not measured claims or a promise of zero system overhead. Report Apple's Find My usage separately from this app's own usage. Defer optional features that add continuing background work.

## First public preview: settings

Use one compact native settings window. Keep setup controls prominent on first launch and collapse the permission explanation once access is working.

| Control | Default and behavior | Completion check |
| --- | --- | --- |
| Device | No default device. Refresh on explicit request; retain one selected exact name locally. Indicate duplicate, missing, and unsupported names with a useful explanation. | No automatic first-device selection. Changing phones updates all labels immediately. Every sound request revalidates the selection. |
| Play Sound | Explicit action on the selected phone, with a note that it makes a real sound and may be delayed. Uses the same path as the menu bar button. | Successful submission is reported without claiming the phone was heard. Test cannot bypass any selection check. |
| Permission status | A clear enabled/needs-attention state and Open Permission Settings action. Explain the broad UI-control permission in plain language. | Detect permission on return from settings and before use, without an idle timer. Provide restart/re-add guidance when appropriate, without altering permissions automatically. |
| Open at login | Off unless the user opts in. Register the main app through Apple's login-item mechanism; show its actual system status. | User can disable it in the app or System Settings. Login opens the menu bar utility quietly and never pings. Registration failure does not leave a falsely enabled toggle. |
| Clear Selection | Clears the local selection, returns to setup, and leaves Find My and the Apple Account untouched. | No later click rings the old selection. Disabled while a request is in progress. |
| Help, Privacy, About | Short setup/recovery guidance, app version, supported interface/OS information, license and source links when published. Privacy text is readable locally. | People can understand stored data, permission scope, removal, and Apple's role without creating an account. |

Use [SMAppService.mainApp](https://developer.apple.com/documentation/servicemanagement/smappservice) for the optional login item. Read the system's registration/approval status rather than storing an independent true/false claim. Introduce this after the name, install path, and signing approach are settled.

## Everyday menu bar behavior

- A normal click opens a standard AppKit menu. The first action names the selected device: Play Sound on [device]. If setup is incomplete, the action is disabled and a short status explains what is needed. Merely opening the menu does not open Find My, refresh devices, or send a sound.
- Settings, Open Find My, About PhonePing, and Quit are visible in the same menu. Use standard menu keyboard navigation, Command-comma for settings, and Command-W for closing windows. Reopening the app also opens settings. An optional direct-click mode is deferred.
- Use a template symbol that follows the system appearance. Show working, request-submitted, and needs-attention states through both text/accessibility labels and the icon; do not rely on color alone.
- Keep one operation active at a time and discard clicks while it runs. Add a short three-second duplicate-activation guard after submission or an uncertain result, without queueing extra requests.
- Report “Asked Find My to play a sound” after the UI action succeeds. Keep the latest result in memory for the menu/settings, then return the icon to its idle state. Do not show “Your phone is ringing” without evidence.
- An unknown result says “Couldn't confirm the request. Check Find My before trying again.” Offer Open Find My and keep the uncertainty visible. No automatic sound retry.
- Avoid routine success notifications, extra permission prompts, or opening settings after a successful menu bar request. Keep actionable failures easy to reach.
- Try Find My without activation. If it is closed, request a nonactivating launch with controls available. Unhide an already-hidden instance, then restore it only after verified playback or before-submission failure. Quit a newly started instance only under the same guarded conditions. Leave existing visible, user-activated, and pending/uncertain sessions alone. If controls are unavailable, offer Open Find My explicitly. Do not restore focus automatically or interrupt someone who switched apps during the request.

## State and recovery rules

| State | User sees | Allowed next step |
| --- | --- | --- |
| No selection / no permission | Setup required, with the specific missing step | Open settings; no sound submission |
| Saved selection, not yet read this session | Saved phone name, without an online/verified badge | Click to discover and validate it on demand |
| Reading or requesting | Working indicator and disabled repeat action | Wait; never queue another ring |
| Known duplicate / missing / invalid name | Specific explanation with Refresh or naming guidance | Resolve and revalidate; never fall back to another phone |
| UI action accepted | Asked Find My to play a sound | Find the phone; Apple controls delivery |
| Action outcome uncertain | Could not confirm; check Find My | Inspect Find My before an explicit new attempt |
| Unsupported interface / permission revoked | Needs attention and a recovery action | Open Find My or permission settings |

Keep the selected name separate from operation results so stale success messages do not follow a newly chosen device. Discovery needs a total time budget, fresh references after transient errors, and a final target/action check immediately before submission. Start with a ten-second discovery budget checked between bounded accessibility calls, then validate the user experience on actual hardware. That budget is not a sound-delivery guarantee.

## Duplicate names and renames

The preview requires a unique exact name as shown in Find My. Apple Account and Find My can temporarily show different names; the latter is the UI this app operates. No documented force-refresh procedure or guaranteed rename propagation time was found. Do not suggest signing out, disabling Find My, or removing a device merely to refresh its name.

An eventual picker may display transient availability labels and place a nearby candidate first as a suggestion. Availability must never silently change the saved target. An explicit duplicate-name picker requires a verified stable identity exposed through the supported interface before it can support repeat use. Do not substitute a row index, location, or online status for identity.

## Next UX priorities

1. Resolve inconsistent temporary Find My cleanup. A normal quit request was recorded in build 10, but the process remained running. Keep existing/user-activated and pending sessions protected.
2. Complete keyboard navigation and VoiceOver checks in the installed app. Escape dismisses the finished diagnostic; the desktop tool did not establish Command-W closure.
3. Validate two signed updates and a clean drag-to-Applications install when the signing identity is ready. Permission refresh is currently the largest setup burden.

The next optional conveniences should be a user-chosen keyboard shortcut, opt-in Open at Login, and Copy Troubleshooting Details. Keep each explicit, local, and off until requested. The report must omit names, locations, account details, paths, and raw UI text. An original app icon and a short setup image are useful release assets after the public name is settled.

Use standard shortcut conventions rather than taking over a common system command; see [Apple’s keyboard guidance](https://developer.apple.com/design/human-interface-guidelines/keyboards). For login, Apple exposes the main app as a login item through [SMAppService](https://developer.apple.com/documentation/servicemanagement/smappservice). These are proposed additions, not features in build 10.

## Optional follow-up features

| Feature | Proposed behavior | When to add |
| --- | --- | --- |
| Keyboard shortcut | Default None. A user-selected shortcut invokes the same guarded action. Offer clear/remove, report conflicts, and unregister on quit. Avoid broad keystroke monitoring; verify a native registration approach first. | After the click flow, permission recovery, and concurrency tests pass. |
| Copy troubleshooting details | Explicit local preview and copy only: app/macOS version, interface language, permission state, and generic error code. Exclude phone names, location, account identifiers, UI dumps, and paths containing usernames. | When supporting outside testers. No automatic upload. |
| More languages / macOS versions | Separate verified interface adapters with synthetic fixtures and manual validation. | In response to test coverage and community demand. |

Sound volume, duration, custom tones, and flashing are not first-release settings: this implementation invokes Apple's existing Play Sound control and has no verified controls for those options. Multi-device dashboards, location history, and background device monitoring are outside the initial product scope.

Apple documents that an online device's sound follows a short delay, while an offline request can wait until reconnection. Its [Play Sound guide](https://support.apple.com/en-ca/guide/findmy-mac/fmm48b093e33/mac) also explains how to stop the sound on the iPhone. Link to this from help rather than adding unverified sound controls.

## Implementation order and release checks

1. **Reliable request:** address the [review findings](REVIEW.md), establish complete device enumeration for the supported layout, resolve permission detection, and hear a real request on the intended iPhone.
2. **Clear settings and feedback:** unify model/menu state, improve known-invalid selections and recovery messages, keep permission checks event-driven, add the accessible menu action, and validate the duplicate-activation guard.
3. **Ready for outside testers:** settle the public name and bundle identity, add About/help/privacy and opt-in login, validate launch/relaunch/removal, and document the actual tested OS/language. Update privacy documentation whenever another preference is introduced.
4. **Small reviewed publication:** finish the test matrix, check the release diff for personal data and secrets, run CI, and optionally obtain a maintainer-requested Claude review of source and synthetic fixtures. Human review remains responsible for merge/release decisions. Publish only with maintainer approval.
5. **Follow-up:** add a shortcut or troubleshooting copy action only after the core flow is dependable. Reassess scope from real feedback.

Acceptance includes a real-device happy path, long-list duplicate handling, wrong details/unknown dialog rejection, offline and uncertain outcomes without retries, permission revocation, repeated clicks, clean relaunch, VoiceOver/keyboard navigation, and system light/dark appearance. Tests for the adapter must assert exact action counts and targets; name-policy unit tests alone do not satisfy these checks.
