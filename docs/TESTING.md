# Testing

Automated tests use synthetic names and do not launch Find My or make network requests. Run:

```sh
bash scripts/test.sh
bash scripts/build.sh
```

## Build 12 existing-instance check — October 12

Find My was explicitly opened before a single Settings sound request. An independent process check confirmed it was already running. The diagnostic recorded sound invocation, observed playback, no newly identified process, Find My active during the operation, and Kept open: activated during operation. The maintainer confirmed audible ringing and reported that Find My came forward. Escape dismissed the diagnostic successfully.

This verifies that an active existing session was preserved, but does not establish foreground preservation for the already-open case. The setup used Open Find My immediately before returning to PhonePing, and the desktop tool did not independently establish the frontmost app before submission. A repeat from a maintainer-confirmed foreground state is pending. Do not classify the activation as solely a setup artifact or claim this path stays behind without that evidence. The previously verified cold-launch result remains separate.

## October 12 source-publication check

An isolated copy of the 62 eligible source files, initialized with a public no-reply identity, passed all 120 Swift tests, 23 privacy regressions, release compilation and packaging, strict local signature verification, plist validation, and shell syntax checks. Its source commit and nonignored files pass the publication guard. The test copy contains no local app preferences or personal Find My captures. The installed app was not rebuilt; these changes affect publishing checks, CI configuration, and documentation.

Four privacy regressions failed before their corrections and passed afterward. See [Repository privacy](REPO-PRIVACY.md) and [Publishing](PUBLISHING.md). The configured GitHub workflow remains unexecuted until a repository exists; local results are not a hosted-CI result.

## Build 12 selected icon — October 12

The maintainer selected design B: a graphite phone, neutral screen, grey ringing marks, and a transparent background. Build 12 packages that artwork plus the previously tested accessibility and reliability follow-ups below. The menu bar implementation is unchanged from the pre-update source. All ten ICNS representations match the rendered source pixels when decoded by macOS ImageIO; light/dark and small-size previews were inspected.

All 120 Swift tests and 16 privacy regression tests pass. Release compilation, publication scanning, plist/shell validation, whitespace checks, and the installed bundle's strict signature verification pass. The packaged icon matches the source resource byte for byte. Build 11 is retained as the local rollback copy.

The running About panel visibly shows the selected icon and Version 0.1.3 Preview (12), with the public handle and company credits. The saved selection was retained. After the maintainer refreshed the existing permission, reopening Settings updated access to Allowed without rebuilding or restarting PhonePing. One Settings sound request recorded playback observed, a new Find My process, no activation, and Normal quit confirmed. Independent process checks found Find My absent before and after the request. The maintainer confirmed the iPhone rang and Find My stayed behind the current window. No second sound request was sent. This verifies one cold-launch request on build 12; existing-playback handling and other window configurations remain separate live checks.

The earlier source-only entries below describe their state before this installation.

## October 12 icon integration

The app now has two editable SVG icon sources, an optical variant for small sizes, and a native ICNS resource referenced by the bundle and About panel. Light and dark previews at 16, 32, 64, and 128 pixels were inspected. macOS ImageIO decoded all ten packaged representations with the same rendered pixels as their source PNGs. The icon packaging helper reproduced the committed resource byte for byte.

All 120 Swift tests, release compilation, 16 privacy regressions, the publication scan, plist/shell validation, and a separate staged bundle's strict signature verification pass. The installed build 11 executable checksum is unchanged; it was not restarted. The new icon awaits the next installed preview. See [artwork sources and export instructions](../Resources/Artwork/README.md) and [publication review](REPO-PRIVACY.md).

## October 12 reliability follow-up

The [Find My CLI review](FINDMY-CLI-REVIEW.md) records two source fixes: an informational result for verified existing playback, and one guarded attempt to dismiss prior details. Four initial regression tests reproduced the old behavior, including 16 Close attempts and an unavailable-action result for the recognized Playing state. All 120 Swift tests now pass (12 policy, 16 model/menu, 54 adapter/diagnostic, 12 quit-preparation, 26 lifecycle), and release compilation passes. Privacy checks and their 12 regressions pass. The installed build 11 is unchanged; new behavior still requires a packaged live check. No sound request was made in this pass.

## Current source accessibility follow-up

After build 11, a synthetic regression reproduced a native menu accessibility label losing the distinguishing suffix of a long device name. The menu now retains the full name in its accessibility label while keeping the visible title compact. The regression also covers changing and clearing selection. All 108 app tests pass: 12 policy, 15 model/menu, 45 adapter/diagnostic, 12 quit-preparation, and 24 lifecycle tests. Release compilation passes. This source change has not been packaged or installed; build 11 remains the live-tested app. No Find My sound request or live VoiceOver validation was performed in this follow-up. See [RESEARCH-FOLLOWUP.md](RESEARCH-FOLLOWUP.md).

## Release packaging follow-up

The local disk-image helper passed a real creation, integrity, and read-only mount check. The visible payload contains only PhonePing.app and a symlink to Applications. The packaged executable matches the installed build byte for byte and its existing signature verifies. The image was ejected after inspection. An existing image was refused without changing its checksum; missing arguments, a missing app, a missing release signing identity, and the ad-hoc app were refused before any notarization upload. Shell syntax checks pass. The unsigned preview stays outside the project as a local test artifact.

Release tooling now stages a signed/notarized DMG plus the stapled-app ZIP and checksums. Both artifacts must pass their checks before release files appear in dist. The disk image signing identity must match the app's signing identity. Actual Developer ID signing, Apple notarization, clean-Mac installation, and signed updates are still untested. This work did not replace or re-sign the installed app.

## Build 11 repeat check

One additional cold-launch Settings request recorded playback, a newly identified Find My process, no activation, and Normal quit confirmed. Find My was absent before the request and the diagnostic reported it absent afterward. On October 12, the maintainer confirmed the phone rang and Find My stayed behind for this repeat. Escape dismissed the diagnostic. The desktop tool continued exposing Settings after Command-W and the Close button; those tool-driven closure attempts remain unverified and are not classified as an application defect. The maintainer subsequently confirmed closing only Settings. The five-minute measurement retained the same process and recorded 0.5986% of one CPU core and 36.27–37.47 MiB physical footprint over 300.005 seconds. Find My was absent before and after sampling. See [PERFORMANCE.md](PERFORMANCE.md) for wakeups, conditions, and limits.

## Build 11 cleanup check

Build 11 passes 107 synthetic tests: 12 policy, 14 model/menu, 45 automation/diagnostic, 12 quit-preparation, and 24 lifecycle tests. Release compilation, packaging, and strict signature verification pass. The app is installed at the same path, with build 10 retained for rollback. The maintainer refreshed the existing permission and PhonePing showed Allowed. One cold-launch Settings request observed playback, identified a new Find My process, recorded no activation, and reported Normal quit confirmed. Independent process checks found Find My absent before and after the request. The maintainer confirmed that the iPhone kept ringing after Find My closed and that Find My stayed behind the current window. See [CLEANUP-FIX.md](CLEANUP-FIX.md).

## Earlier live results

Preview 0.1.3 build 9, macOS 27.0.1, English Find My, arm64: the maintainer used the menu bar Play Sound action once from a confirmed closed Find My and reported that the intended iPhone rang while Find My stayed behind. The temporary Find My process exited afterward. The read-only diagnostic recorded playback observed, new process identified, no activation, and a normal quit request. It did not relaunch Find My or send another sound. This verifies one cold-launch path; the matrix below keeps other scenarios separate.

## Settings source follow-up

Build 10 passed 87 synthetic tests (12 policy, 14 model/menu, 45 adapter/diagnostic, 16 lifecycle) and release compilation. A regression test first reproduced empty discovery losing its recovery message, then passed with the fix. The Settings preview uses fictional devices and in-memory preferences; no real Find My or sound action was performed during this pass. Light/dark layout, setup, empty/duplicate lists, long names, busy/uncertain states, help scrolling, and diagnostic dismissal with Escape were checked. Full keyboard navigation and VoiceOver remain pending. The separate preview left build 9 unchanged; the maintainer subsequently authorized packaging and installation as build 10. See [UI-POLISH.md](UI-POLISH.md).

## Build 10 installed check

Build 10 was installed at the existing path after quitting PhonePing, with build 9 retained as the rollback copy. All 87 synthetic tests, release packaging, and strict signature verification passed. The saved device choice was retained. The maintainer refreshed the existing permission after the ad-hoc signature changed, and the app showed Allowed. With Find My confirmed not running, one Settings Play Sound action reported a submitted request. The local diagnostic recorded playback observed, a new process, no activation, and Normal quit requested. Find My was still running afterward and exposed controls to the read-only diagnostic. No second sound request or forced termination was sent. The maintainer confirmed the intended iPhone rang and Find My stayed behind the current window. Diagnostic dismissal with Escape passed in the installed app. The desktop tool did not establish Settings closure with Command-W or the Window menu, so those checks remain unverified.

## Manual matrix

Use your own iPhone. Confirm sound delivery by hearing the phone or checking its Find My alert; an accepted Accessibility action alone is insufficient.

| Scenario | Expected result | Status |
| --- | --- | --- |
| First launch without permission | Setup explains permission; sound is unavailable | Observed |
| Enable permission | Refresh becomes available, or restart guidance appears | Observed after re-adding the current app at its stable location |
| Refresh Devices | Device names appear; no private status labels are persisted | Live names-only list observed; persistence remains source-reviewed |
| Choose one uniquely named iPhone | Selection persists locally | Observed in 0.1.3 build 4; retained after build 5 launch |
| Click Play Sound | Requests sound for the uniquely verified selected iPhone | Build 7 visible-window and builds 8/9 cold-launch requests rang the intended iPhone, confirmed by the maintainer; other devices were not independently monitored |
| Click menu bar icon | Opens the native menu without scanning devices or requesting a sound | Maintainer used the native menu in build 9; absence of discovery/sound on menu opening is source-reviewed and synthetic-tested, not independently instrumented live |
| Choose Play Sound in menu | Requests sound for the device named in the action | Build 9: maintainer selected the action and confirmed the intended iPhone rang |
| Find My closed | Launches without requesting activation; requests sound and preserves foreground work | Build 11 observed playback and confirmed process exit without activation; the maintainer confirmed the phone kept ringing after Find My closed and Find My stayed behind. Build 9 previously exited; builds 8 and 10 left Find My running |
| Find My already hidden | Unhides without requesting activation; restores hidden state only when safe | Build 7 deliberately hidden sound attempt failed before submission; build 8/9 unhide path still needs live validation |
| People or Items selected | Switches to Devices before resolving a target | Pending |
| Another device details open | Dismisses known details and reselects target | Pending |
| Duplicate phone name | Stops; asks for a unique name | Unit tested; duplicate-name warning observed in the live app |
| Phone name changes | Stops instead of selecting another device | Unit tested; live pending |
| Name contains a comma | Full details verification prevents truncated-name selection | Unit tested; live pending |
| Phone offline | Never claims the phone rang; Apple may queue the sound | Pending |
| Rapid repeated clicks | Only one operation runs at a time | Synthetic model test passed; live pending |
| Revoke Accessibility | Stops and explains the required permission | Pending |
| Unknown dialog / unsupported language | Stops without clicking unrelated controls | Pending |
| Relaunch PhonePing | Remembers selected name; no automatic ping | Selection retained across local restarts through build 9; no automatic request observed; storage scope source-reviewed |
| Change selection after setup | Menu bar tooltip, accessibility label, and result state immediately match the new selection | Source fixed in 0.1.1; model test passed, live pending |
| Saved name becomes duplicated | Settings explains the problem and blocks a known-invalid selection | Source fixed in 0.1.1; model test passed, live pending |
| Device list exceeds window height | Enumerates the complete supported list; off-screen duplicate cannot be mistaken for uniqueness | Pending release gate |
| Transient accessibility read failure | Bounded discovery can recover without repeating a submitted sound action | Synthetic adapter tests passed in 0.1.3; live failure injection not performed |
| Sound action times out after invocation | Reports an uncertain outcome; no automatic resubmission | Model and adapter fault-injection tests passed in 0.1.3 |
| Permission setup closed | No permanent two-second permission timer remains active | Source verified; build 5 idle counters recorded below |
| Five-minute idle / repeated requests | Record CPU, physical memory, wakeups and recovery; no background device scans or sustained memory growth | Build 11 completed a five-minute post-request idle sample in the same process with Settings confirmed closed. Active request cost, immediate recovery, and repeated-use resource measurements remain pending. See [PERFORMANCE.md](PERFORMANCE.md) |
| Multiple candidate details sheets | Stops unless exactly one valid target/action context is established | Synthetic adapter test passed in 0.1.3; live check pending |
| Keyboard and VoiceOver use | Settings and menu actions are reachable and names/status stay accurate | Pending |
| Open at login opted in/out | Reflects system status; launches quietly and never automatically pings | Planned feature; not implemented |
| Optional shortcut | Same guarded path, conflicts handled, one activation per key press | Deferred feature; not implemented |

## Development history

The entries below describe the state at the time of each check. Use the current result and matrix above for the latest status.

## October 11 permission and device-list check

The relocated app recognized its permission and Refresh successfully displayed the device picker. The selected phone could not yet be resolved uniquely: Find My still exposed duplicate names after quitting and reopening it. The live app displayed its duplicate-name error. A successful sound request and audible result remain unverified; no bypass of exact-name selection was made. No personal device names or status/location labels are recorded here.

## October 11 review verification

The existing 10 policy tests and release compilation passed again during the [prototype review](REVIEW.md). No live sound request was made during that review. The existing packaged app was not replaced or re-signed. New settings and features in [SETTINGS-PLAN.md](SETTINGS-PLAN.md) remain proposals.

## Local preview 0.1.1

Nineteen synthetic tests (12 policy, 7 model) passed on October 11, both in the staging copy and the relocated project. The release build packaged preview 0.1.1 (build 2), and strict local signature verification passed. The bundle uses approximately 420 KiB of allocated disk space on this Mac; this is not a memory-usage figure. The relocated build reported stale cache paths from the earlier project location but completed successfully. The model tests cover status updates, known duplicates, revoked permission, one in-flight request, uncertain outcomes without retry, no automatic settings reveal, and stale-refresh clearing. They use in-memory preferences and a fake service; they do not validate the Accessibility adapter.

The maintainer reported an audible Apple Watch test through the earlier build. This is user-reported live evidence, not assistant-observed delivery, and it does not establish hidden operation in 0.1.1. The intended iPhone test remains blocked by duplicate names in Find My.

The rebuilt settings window and expanded local privacy/help were inspected on macOS 27.0.1; the displayed controls and text fit the window. The saved selection was retained. macOS no longer reported the Accessibility grant after rebuilding the ad-hoc signed app, so Refresh and Play Sound correctly remained disabled. Re-adding the current app was requested. Hidden Refresh, cold launch, and audible background delivery remain unverified for 0.1.1; no sound was submitted during this update. Idle CPU, physical memory, and wakeups were not measured.

## Local preview 0.1.2

The native refinement removes the large branding header, promotional footer, custom accent styling, oversized sound button, and hidden right-click flow. It adds a standard AppKit menu, grouped SwiftUI settings, a standard About panel, Command-comma/Command-W support, concise menu status, and full recovery text in settings. Twenty-three tests (12 policy, 11 model/menu) passed in staging and in the project folder. The release build and strict local signature check passed. New coverage checks that opening a menu performs no discovery or sound action, revoked permission disables the menu action, errors remain visible without a selection, and restoring permission clears obsolete errors.

Before replacing 0.1.1, the maintainer restored permission. Refresh succeeded after hiding Find My and again after quitting Find My. These observations establish device-list reading for those transitions; they do not establish audible background delivery or guarantee that Find My never changes its own window visibility. A request already in progress when the assistant inspected the app ended with Play Sound unavailable; the assistant did not initiate that request. Background ringing remains a release gate.

The rebuilt 0.1.2 settings window and standard About panel were inspected. The initial permission/setup controls and collapsed help row fit the window after correcting its height. Command-W closed the About panel and returned to settings. The live menu-bar interaction check was interrupted by a desktop-control tool timeout; it remains pending, along with full VoiceOver and dark/high-contrast appearance checks. Expanded-help interaction also needs a manual check. This rebuild again lost the ad-hoc build’s permission association, so no sound was submitted from 0.1.2. No new permission type was introduced.

## Evidence discipline

After removing the idle permission timer on October 11, all 10 tests passed again and `scripts/build.sh` successfully built, packaged, and verified the local app signature. No Find My request was made as part of that build. Event-driven permission recovery and resource measurements remain live checks to complete.

Record OS and app versions and which scenarios were actually tested. Do not commit raw AX dumps, locations, serial numbers, account emails, or screenshots containing real Find My data. Tests do not establish compatibility with macOS versions that have not been exercised.

## Local preview 0.1.3, build 5

Forty-three automated tests passed in the real project folder: 12 policy, 11 model/menu, and 20 synthetic adapter tests. The local release-configuration build and strict signature verification passed. Build and notarization scripts rejected a missing Developer ID identity/ad-hoc artifact before any upload. Signed release success and notarization remain untested while Apple Developer enrollment is pending.

Build 4 refreshed the complete expanded device list and allowed selecting the now-uniquely-named intended iPhone. One hidden request and one explicit-open recovery attempt ended with Play Sound unavailable; no sound invocation was reached. The recovery attempt opened the correct device details. Build 5 adds focused/main-window discovery and a static-text-value fallback, both covered by regression tests. The earlier failures do not establish background ringing support.

The Help and Privacy label now expands and collapses its content on click and exposes its state to Accessibility. Expanded text could be scrolled to the bottom. Full keyboard traversal, VoiceOver, dark mode, and high contrast remain manual checks. No personal UI capture was saved into the repository.

Build 5's five-minute idle sample completed with settings closed, a saved name, and permission not yet recognized after rebuilding. It used 0.188371 CPU seconds over 300.002 seconds (0.0628% of one core), 24.70–25.56 MiB physical footprint, and 86.08–92.97 MiB resident memory. There were zero package-idle wakeups and three interrupt wakeups. This excludes Find My and active request costs; the permission-enabled, post-request baseline remains pending. See [PERFORMANCE.md](PERFORMANCE.md). At the final live inspection, permission was still required, so build 5's corrected sound path was not exercised.

## Build 5 permission-enabled retest, October 11

After the maintainer refreshed permission, restarting PhonePing changed access from Required to Allowed. The saved uniquely named iPhone selection was retained. The hidden request still returned Play Sound unavailable before submission. Visible-window comparisons also stopped before submission; one comparison reported an unsupported interface during a window transition. The intended device's expanded row and details sheet were visible during inspection, but no audible delivery or successful sound action was established. The details-discovery correction is therefore not a confirmed fix. No app rebuild or permission change was made during these retests. Further diagnosis must establish the native control attributes rather than inferring them from formatted UI descriptions.

## Build 6 diagnostic preparation, October 11

With explicit maintainer authorization, the standalone read-only check was attempted inside and outside the command sandbox. Both attempts stopped at the Accessibility trust check before reading Find My. No permission was requested or changed. This does not revoke or contradict the separate permission granted to PhonePing.

Build 6 adds an explicit diagnostic under Help and Privacy inside PhonePing. It shares the app's permission and reports fixed control vocabulary, counts, and name-equality results. It does not navigate Find My, launch it, or invoke Play Sound. Dismissing the report clears it from the model. The sound-navigation implementation is unchanged; this build is for gathering evidence, not a claimed ringing fix.

Fifty-three synthetic tests passed in staging and in the real project: 12 policy, 13 model/menu, and 28 adapter/diagnostic tests. New checks cover no launch/navigation, permission denial, concurrent-click guarding, preserved failure status, personal-text exclusion, numeric classification, header matching, cycles, skipped map contents, and the diagnostic deadline. The local release build and strict signature verification passed. The installed bundle identifies itself as version 0.1.3, build 6.

The new Help and Privacy entry was inspected live. Run Diagnostic is disabled while access is Required, as intended. This rebuilt ad-hoc app requires the maintainer to refresh its permission association before the live report can be read. No Find My inspection or sound request was made by build 6 during this check. Live report inspection and sound delivery remain pending.

## Build 6 live diagnostic and build 7 correction, October 11

After the maintainer refreshed permission and PhonePing restarted, access became Allowed. The diagnostic initially reported that Find My was not running and did not launch it. Find My was then opened explicitly, the uniquely named intended device selected, and its details opened without invoking sound.

The diagnostic completed with zero read failures. It found one details sheet, a full-name match, and a `FMPlatterButton` with actual description `Play Sound,Off` and boolean enabled state. It found no matching device rows and no Devices-tab roles while details were open. No raw tree or personal UI capture was saved. This establishes the modal-list transition that the old controller failed to handle; it does not establish sound delivery.

Build 7 follows details after selecting a uniquely verified row, rechecks any still-exposed device list, and verifies the full header immediately before sound submission. It also retries an absent Devices tab within the existing discovery budget during window transitions. Six new regression tests cover a modal replacing the list, wrong names with a hidden list, disabled sound, a partially exposed list, an empty list container, and a temporarily absent tab. All 59 tests passed in staging and the real project (12 policy, 13 model/menu, 34 adapter/diagnostic).

The modal-list regression was also run against the earlier build 6 controller, where it failed with `unavailableAction`; it passes with the correction. An initial attempt at that comparison failed to compile because the command omitted the project's writable module-cache setting; that invocation was not counted as a regression result.

The release-configuration package build and strict signature check passed. The installed bundle reports version 0.1.3 build 7. On opening, access was Required and sound remained disabled, so the maintainer was asked to refresh the changed development signature's permission association. No sound was submitted from build 7 during this turn. Live ringing from the corrected build remains unverified.


## Build 7 live request, October 11

After the maintainer refreshed permission, PhonePing reported Allowed. One request from settings with Find My hidden returned Play Sound unavailable before submission. The existing read-only diagnostic then completed with zero read failures: one matching device row, AXPress available, no Open Details match, and no details header or action controls. This narrows the remaining failure to hidden-window navigation; it does not establish its underlying cause.

Find My was explicitly raised, and a separate request from PhonePing settings returned Sound requested in Find My. The maintainer confirmed that the intended iPhone audibly rang. No further sound request was sent. This verifies one visible-window path on macOS 27.0.1, not hidden operation, cold launch, the menu-bar interaction itself, repeated-use reliability, or other OS versions. The earlier modal regression correction is now supported by this visible-window result.

No code, packaged app, signature, or permission was changed during these checks. Only sanitized findings are recorded here; no personal device names, locations, screenshots, or raw trees are saved.

The permission-enabled post-request sample ran for five minutes without process replacement: 0.6068% average CPU on one core, 37.24–39.16 MiB physical footprint, 99 package-idle wakeups, and 397 interrupt wakeups. Final settings visibility was not independently verified, so a controlled windows-closed comparison remains pending. Find My was not included. See [PERFORMANCE.md](PERFORMANCE.md).

After the maintainer supplied the full company name, the About source and project credits were corrected to Lanza Studios Inc. All 59 existing tests passed, and arm64 release compilation succeeded. The installed build 7 bundle was not replaced or re-signed, so the About-panel wording will appear in the next packaged build without forcing an immediate permission refresh for this copy change. Documentation formatting and git diff whitespace checks passed.


## Build 8 background-operation candidate, October 11

Before this update, a build 7 request exposed the exact Find My action description `Play Sound,Playing…`. The maintainer reported manually closing Find My after playback started without interrupting the sound. A later process-presence check found Find My no longer running. This supports testing cleanup after observed playback; it does not establish behavior before delivery or while offline.

Build 8 changes launch from deliberately hidden to nonactivating with controls visible, supports bounded unhiding, and scopes a Find My activation observer to each explicit operation. After exactly one sound submission, it reads the verified details for up to five seconds for the exact Playing status. Only then may it ask a newly launched Find My to quit or restore an initially hidden instance. Existing visible instances and any instance activated during the operation are left alone. Pending/uncertain outcomes never close Find My or resubmit the sound. Unknown or older launch dates do not authorize quitting. The normal quit request is not a force quit.

All 82 tests passed in staging and in the actual project: 12 policy, 13 model/menu, 43 adapter/diagnostic, and 14 lifecycle tests. Coverage includes playback confirmation, pending/uncertain requests, changed details after submission, missing sheets, read-only diagnostics, lifecycle restoration, launch failure, unhide timeout, cancellation, user activation, unknown/older launch dates, and observer cleanup. The real-project release package and strict signature verification passed; the installed version is 0.1.3 build 8. The company credit in this package is Lanza Studios Inc.

An initial staging documentation-update command used the wrong relative path and stopped before changing files. It was corrected; this was not a test failure. No personal UI captures or raw trees were saved. The staged build's user-cache warnings were confined to unavailable optional compiler caches; tests and release compilation completed successfully.

On opening the installed build, macOS reported access as Required and sound remained disabled. The maintainer was asked to refresh the changed ad-hoc signature's existing permission association. No sound request has been made from build 8 yet. Foreground preservation, background audible delivery, and automatic cleanup remain live checks in [BACKGROUND-OPERATION.md](BACKGROUND-OPERATION.md).


## Build 8 background test and build 9 follow-up

After the maintainer refreshed permission and PhonePing restarted, access showed Allowed. A process-presence check found no Find My process. One Play Sound action returned “Sound requested in Find My.” The maintainer confirmed that the intended iPhone rang and Find My stayed behind. A subsequent process check still found Find My running. Automatic cleanup did not complete in this case; the existing diagnostic was not sufficient to attribute that to playback observation, ownership, activation, or a declined quit request. No second sound request was sent during investigation.

Build 9 adds a fixed-state, memory-only last-operation summary to the existing read-only diagnostic, plus the reviewed Settings improvements. No cleanup guard is relaxed. All 86 synthetic tests pass (12 policy, 13 model/menu, 45 adapter/diagnostic, 16 lifecycle). The cleanup reason and further live cases still need validation.

A separate UI preview used only fictional devices and in-memory preferences. Permission-required/allowed, expanded help, and long-name states were inspected in dark appearance. Controls and text fit; the full long name is exposed in the picker accessibility value. No real permission changes or Find My actions were made by this preview. Full VoiceOver, keyboard traversal, light, and high-contrast checks remain open.

Build 9 was then tested and packaged in the project folder: all 86 tests passed, the release build succeeded, strict signature verification passed, and the bundle version is 9. The installed Settings screen shows the revised permission-first layout and access Required. The maintainer was asked to refresh the same permission; no build 9 sound request has been sent yet.


## Appearance follow-up, build 9 source

A separate preview compiled from the current source used fictional device names and in-memory preferences. The permission-required screen and a long selected name fit in the light layout; the full name remained in the accessibility value. An app-only high-contrast appearance override also rendered without clipping, but this does not establish behavior with the system Increase Contrast setting or full assistive technology. System appearance and accessibility preferences were not changed. A Tab press did not move focus under the current configuration; complete keyboard traversal and VoiceOver remain unverified. No sound or real Find My action was triggered.


## Build 9 menu-bar background and cleanup check, October 11

After the maintainer re-added the installed build, access showed Allowed. The maintainer quit Find My manually, and a process-presence check found no Find My process immediately before the test. The maintainer then clicked the PhonePing menu bar icon and chose Play Sound once, reporting: “Rang; Find My stayed behind.” Subsequent process checks found no Find My process.

The existing read-only diagnostic showed sound invocation attempted, playback observed, new process identified, initially hidden false, activated during operation false, and “Normal quit requested.” It also reported that Find My was not running. The diagnostic was dismissed without saving or copying its output. These fixed facts support one successful cold-launch menu request and automatic cleanup; no personal labels or raw UI trees are recorded here.

The evidence does not establish an initially hidden/existing-visible instance, minimized windows, full-screen Spaces, offline delivery, repeated-use reliability, or other OS versions. Sound continuing after automatic exit was not separately timed; the earlier manual-close result remains distinct. No further sound request, code change, rebuild, or permission change was made during this check.
