# Quality and security review

October 11, 2026. Scope: preview 0.1.3 through build 11 and the subsequent menu accessibility source fix, including Settings polish, local repository history, packaging, CI, and primary alternative documentation. This is a source review and local test record, not an independent audit or an Apple endorsement.

**Build 11 passed one local cold-launch test with continued ringing, foreground preservation, and confirmed cleanup. Public release validation is incomplete.** The maintainer confirmed that the iPhone kept ringing after Find My closed and that Find My stayed behind. Independent process checks and the local diagnostic confirmed exit after playback. Builds 8 and 10 had left Find My running; those earlier results remain recorded. Repeated-use reliability and other window states still need live checks.

## October 12 source follow-up

The adapter now reports verified existing playback without submitting another sound. Preparation checks recognized details and an enabled Close action, and sends Close at most once even when ignored or failing. The old behavior was reproduced before correction. All 120 Swift tests, release compilation, the privacy scan, and 12 privacy regression tests pass. The installed app remains build 11; these fixes have no live validation yet. See [the comparison and release checks](FINDMY-CLI-REVIEW.md).

## Findings and priorities

| Priority | Finding | Status / next evidence |
| --- | --- | --- |
| Release gate | Find My exposes a UI, not a stable device identity API. A duplicate omitted from a virtualized list could escape the uniqueness check. | The adapter rejects visible scrolling/clipping, unreadable names, and ambiguous details. Validate a long list with a duplicate beyond the visible region on every supported layout. If completeness cannot be established, leave that layout unsupported. No wrong-device incident was observed. |
| Release gate | Nonactivating launch and unhide do not prove that Find My keeps the user's foreground app undisturbed. | Build 8 checks exact playback status before cleanup and leaves pending/uncertain or user-activated sessions alone. Build 9 completed one cold-launch ring with foreground work preserved and the temporary process gone afterward. Build 10 later left Find My running. Build 11 dismisses verified details before normal quit and has confirmed process exit in one cold-launch test; the maintainer confirmed continued ringing after closure and foreground preservation. Repeated-use reliability remains unverified. Validate hidden, existing-visible, minimized, and full-screen cases. See [BACKGROUND-OPERATION.md](BACKGROUND-OPERATION.md). |
| Release gate | Local ad-hoc signatures do not provide a stable public update experience. | Developer ID enrollment is pending. Settle app name/bundle identity, then test two signed updates for permission continuity and a notarized download. Do not weaken macOS protections. |
| Validation | One settled post-request idle sample is recorded; active cost and repeated-use recovery remain unmeasured. | Build 11 measured 0.5986% of one CPU core and 36.27–37.47 MiB physical footprint over 300.005 seconds, with Settings confirmed closed and the same app process retained. This excludes Find My and is not a battery-life claim or a controlled comparison with the earlier builds. See [PERFORMANCE.md](PERFORMANCE.md). |
| Fixed in source | Required permission appeared below disabled device controls, while the footer asked for an unavailable Refresh action. | Show permission first while required. Hide unavailable device controls, retain Clear Selection for a saved choice, and label initial discovery Find Devices. |
| Fixed in source | General retry guidance did not distinguish an uncertain submission. | Tell the user to check Find My before another attempt. Ordinary usage and privacy now precede diagnostic controls. |
| Fixed in source | Long device names were truncated in the native menu accessibility label as well as the visible title. | The full accessibility label is retained and updated when selection changes or clears; the regression first reproduced the defect. All 108 app tests and release compilation pass. Live VoiceOver validation is pending. |

## Security and local data review

- Runtime source contains no network client, telemetry SDK, updater, shell execution, credential/Keychain access, private framework loading, screenshot capture, or input event synthesis. The package has no external runtime dependencies. This is source evidence, not a packet-capture audit or proof of absence of vulnerabilities.
- The only app-specific saved preference is the selected device name. Accessibility labels may temporarily contain location or status text in memory; the app extracts the name and does not log or persist the suffix. Clear Selection replaces the saved name with an empty value. macOS may maintain its own app preferences and crash reports.
- The diagnostic produces fixed allowlisted labels, types, counts, and equality results. It does not emit arbitrary UI text or identifiers, and it clears its report on dismissal. Synthetic tests cover redaction, bounds, permission failure, and absence of actions.
- The adapter checks a unique exact name, then verifies the full details header and an exact enabled sound control. It never uses availability as identity and never retries after invoking Play Sound. Unknown dialogs or controls stop the operation.
- Accessibility remains broad system permission. The app is not sandboxed; targeting only Find My is a code-level restriction, not an OS-enforced Find My-only grant. Apple's app still performs network delivery. See [PRIVACY.md](../PRIVACY.md).
- A later publication review also checked commit metadata and found a personal email in the sole unpublished commit. It was replaced with the verified GitHub no-reply identity while preserving file contents and uncommitted work. Source credits now use the public handle. The local pre-push guard and 12 privacy regression tests pass; see [repository privacy](REPO-PRIVACY.md) for scope and remaining manual review.
- CI uses a commit-pinned checkout action, read-only repository permission, no persisted Git credentials, no release upload, and synthetic tests. The pin was verified against the [official checkout commit](https://github.com/actions/checkout/commit/3d3c42e5aac5ba805825da76410c181273ba90b1). Release scripts upload only when deliberately invoked by the maintainer; no notarization was run during this review.

No confirmed high-severity vulnerability was found in this bounded review. The unresolved identity/layout risk remains a public release gate even though the existing safeguards and synthetic checks pass.

## Research follow-up

The [research and release priorities](RESEARCH-FOLLOWUP.md) record Apple guidance, related projects, the naming collision, and remaining installation/accessibility/performance checks. The maintainer confirmed organization enrollment as Lanza Studios Inc.; certificate issuance remains pending. The full menu target label is corrected in source with 108 passing app tests and a successful release compilation. The installed build 11 was not replaced, and no sound was requested during this review.

## Build 11 cleanup follow-up

Build 11 dismisses only the verified playing-device sheet before normal quit, checks for process exit, and retains activation protection throughout cleanup. All 107 tests and release packaging/signature checks pass. One cold-launch Settings request observed playback, identified a new Find My process, recorded no activation, and reported Normal quit confirmed. Independent process checks found Find My absent before and after the request. The maintainer confirmed that the iPhone kept ringing after Find My closed and that Find My stayed behind the current window. No force termination, new permission, network access, preference, or idle observer is added. See [CLEANUP-FIX.md](CLEANUP-FIX.md).

## Earlier validation

Build 10 passed all 87 tests: 12 selection-policy, 14 model/menu, 45 adapter/diagnostic, and 16 lifecycle checks. Release compilation also passes. The new regression reproduces and fixes empty discovery losing its recovery message. The Settings changes are installed in build 10, with build 9 retained for rollback. Build 10 passes packaging and strict signature verification. Its first cold-launch Settings request recorded playback and Normal quit requested, but Find My remained running afterward. This confirms cleanup reliability is unresolved; the maintainer confirmed the intended iPhone rang and Find My stayed behind the current window. Build 9 passed all 86 tests, release compilation, packaging, and strict signature verification both in staging and in the project. After the maintainer refreshed the development permission, the installed app reported Allowed and completed the menu-bar cold-launch test with cleanup. No further rebuild or permission change was needed to read the result. Tests use fictional devices and do not launch Find My. Settings-only changes do not add storage, polling, permissions, dependencies, or device actions.

Keep actual delivery, window ordering, offline behavior, VoiceOver, language/OS support, and performance checks separate from synthetic results. A successful AX action means a request was submitted, not that the phone was heard. The [manual test record](TESTING.md) is the source of live evidence.

## Product decisions

Keep normal click → menu → Play Sound on the named device. It makes accidental activation less likely, shows the target, and keeps Settings discoverable. No separate Control Center integration, direct-click mode, location dashboard, or automatic device choice.

The most useful differentiator is a quiet, dependable operation that cleans up only its own temporary Find My instance and leaves the user's existing session alone. One temporary-instance cleanup is now verified; preserving existing and user-activated sessions still needs live checks. A user-chosen keyboard shortcut and opt-in launch at login are later conveniences, after background reliability and signed installation are settled. Avoid features that need background monitoring or new personal data.

Related tools exist; see [RESEARCH.md](RESEARCH.md). Use `Spidersmanz` for repository ownership and credit Lanza Studios Inc. and Spidersmanz. The maintainer prefers keeping PhonePing as the working name. Resolve the documented naming overlap before signed distribution. Publishing, merging, and release approval remain maintainer decisions.


The revised Settings was inspected in a separate local preview with in-memory fictional devices. Permission-required/allowed, expanded help, and a long device name fit the dark layout; the permission-required and long-name states also fit the light layout. The full target name is available in the picker help and Play Sound accessibility label while visually truncating. Full VoiceOver behavior has not been established. An app-only high-contrast appearance rendered without clipping, but system Increase Contrast, full keyboard navigation, and VoiceOver remain unverified. The preview did not use Find My or write real app preferences. Expanded help, busy controls, clearing a saved choice without permission, and diagnostic dismissal with Escape were also checked. See [UI-POLISH.md](UI-POLISH.md).
