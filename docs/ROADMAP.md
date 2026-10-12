# Release plan

The [0.1.3 improvement review](IMPROVEMENTS-0.1.3.md) tracks the current implementation and remaining checks. The [prototype review](REVIEW.md) identifies current findings; the [settings and feature plan](SETTINGS-PLAN.md) defines proposed behavior and acceptance checks. Each checkbox records implementation or verification separately; planned features are not implied to be available.

The [research follow-up](RESEARCH-FOLLOWUP.md) prioritizes the remaining release checks, records the menu accessibility correction, and distinguishes planned distribution work from the installed build.

## 1. Local proof

- [x] Inspect Find My's controls without accessing account tokens or private caches.
- [x] Build a native menu bar app with setup and explicit permission handling.
- [x] Test exact matching, duplicate names, and allowed sound actions.
- [x] Implement reviewed state, transient-discovery, and uncertain-action feedback fixes; live adapter validation remains below.
- [ ] Verify full device enumeration, including long lists and off-screen duplicate names.
- [x] Add synthetic model tests for failure and concurrency paths.
- [x] Add injectable Accessibility adapter tests for transient errors, wrong details, and exact submission counts.
- [x] Reject unreadable device labels and detected clipped/scrolling lists rather than treating a subset as complete.
- [x] Prepare separate local/release packaging, notarization, and checksum tooling; signed release execution requires an account/certificate.
- [x] Verify the inspected expanded device list and one sound request through PhonePing settings on a real iPhone with Find My visible; the maintainer confirmed hearing it (build 7). The menu-bar cold-launch path is now also verified below; an existing hidden instance remains a separate check.
- [x] Report verified existing playback without sending another sound, and attempt only one verified Close during preparation; all 120 Swift tests and release compilation pass. These changes are packaged in build 12; their specific live scenarios remain unverified.
- [ ] Verify repeated use, restarting Find My, offline handling, and revoked permission.
- [x] Implement nonactivating launch, bounded unhide, and cleanup after Find My reports playback (build 8); offer Open Find My on failure. Build 9 verified one cold-launch menu-bar ring with foreground work preserved and the temporary process gone afterward.
- [x] Verify one nonactivating cold-launch sound request on the development Mac (build 8): audible ring and Find My stayed behind, confirmed by the maintainer.
- [x] Verify one temporary-instance cleanup after a cold-launch menu-bar request (build 9): playback and normal quit recorded; process absent afterward.
- [x] Verify one build 10 Settings request after installing the polish: the maintainer confirmed the intended iPhone rang and Find My stayed behind. Automatic process cleanup did not complete.
- [x] Add verified details dismissal and exit confirmation in build 11; one cold-launch request observed playback and confirmed Find My exited without activation.
- [x] Confirm audible continuity and foreground preservation for the build 11 test: the maintainer reported continued ringing after Find My closed and that Find My stayed behind.
- [x] Complete one controlled build 12 existing-visible request: from a maintainer-confirmed foreground state, the phone rang, Find My stayed behind, and the existing window was preserved. The earlier activation was not reproduced; its exact cause remains unproven.
- [ ] Verify initially hidden, minimized, user-activated, and remaining window configurations, plus repeated cleanup reliability.

The live checks are the gate for the behaviors claimed in a downloadable release. A source preview can be published with its unsupported and unverified cases explicit. A successful build alone does not prove the feature works. See [Publishing](PUBLISHING.md).

## 2. Small open-source preview

- [x] MIT license, privacy explanation, contribution guidance, PR/issue templates, and CI configuration.
- [ ] Continue the manual test matrix before claiming broader compatibility; the source preview documents the current gaps.
- [x] Use a standard menu, native grouped settings, concise status, and an About panel.
- [x] Preserve the full target name in the native menu accessibility label when the visual title is truncated; regression and all 108 app tests pass.
- [ ] Complete keyboard/VoiceOver validation on the release build.
- [x] Remove the permanent permission timer in favor of event-driven checks.
- [x] Measure and record a five-minute pre-operation idle CPU/memory/wakeup baseline (0.1.3 build 5).
- [x] Record a five-minute permission-enabled post-request sample (build 7); final settings-window visibility was not independently verified.
- [x] Record a five-minute build 9 sample with Settings confirmed closed after a maintainer restart; this is a fresh-process idle observation.
- [x] Record one five-minute build 11 idle sample after a confirmed ring in the same running app process, with Settings confirmed closed.
- [ ] Compare fresh-launch and post-request idle on the same build to investigate the observed CPU/wakeup difference; the short process sample found no active loop.
- [ ] Measure Find My costs, immediate post-request recovery, and resource use after repeated requests.
- [x] Add About and local help/privacy.
- [ ] Settle app identity and add opt-in Open at login after signed installation is ready.
- [x] Complete a bounded source/privacy/security review and record unresolved release gates. An independent Claude review remains optional and requires maintainer authorization.
- [x] Prepare draft preview notes with verified behavior and limitations; do not publish them as a release yet.
- [x] Confirm repository owner: the connected GitHub account `Spidersmanz`.
- [x] Remove personal email from unpublished commit metadata; configure repository-local no-reply attribution and enable the local publication check. See [repository privacy](REPO-PRIVACY.md).
- [x] Confirm the maintainer prefers PhonePing as the working name.
- [ ] Resolve the existing PhonePing naming overlap before public distribution; see [FINDMY-CLI-REVIEW.md](FINDMY-CLI-REVIEW.md).
- [ ] Create the GitHub repository, enable private security reporting, and require reviewed PRs and passing checks on main.
- [ ] Publish source with explicit compatibility limits after maintainer approval.

## 3. Downloadable release

- [ ] Test more supported macOS versions and both processor architectures before claiming support.
- [ ] Choose a permanent reverse-DNS bundle identifier.
- [x] Confirm Apple Developer enrollment was submitted as an organization, Lanza Studios Inc.; approval and certificate issuance remain pending.
- [ ] Arrange a Developer ID signing identity and notarization; inspect the issued certificate and archive for public identity metadata.
- [x] Implement disk-image packaging with an Applications shortcut and verify a local unsigned preview; release tooling prepares both DMG and ZIP after signing/notarization checks.
- [x] Add editable vector artwork, a small-size variant, native icon packaging, and About-panel integration; staged packaging and image checks pass.
- [x] Install the selected transparent B icon in build 12 and inspect it in the running About panel; the menu bar implementation is unchanged.
- [x] Verify one build 12 cold-launch Settings request after permission refresh: playback and normal exit recorded, Find My absent before and after, and the maintainer confirmed audible ringing with Find My staying behind.
- [ ] Settle the public name and verify the real signed/notarized DMG once the organization certificate is available.
- [ ] Verify a clean installation and two successive signed builds for permission and selection continuity.
- [ ] Build from a reviewed tag, verify signature, notarize, and publish checksums.
- [ ] Add a clean screenshot with fictional device data and a short setup guide.

## Later, only if useful

Optional keyboard shortcut, local troubleshooting details, localized Find My adapters, and better confirmation from observable Find My state. Keep the menu focused on Play Sound and retain the existing privacy boundary. Open at login is planned for the initial public preview after app identity is settled, with the default off.

## Interface decision

Use the menu bar as the single entry point: click the icon, then choose Play Sound on the selected device. Settings and recovery stay in the same menu. The maintainer chose this focused interface on October 11; a separate Control Center integration is out of scope.

The [Watch and Mac controls research](WATCH-CONTROLS-RESEARCH.md) remains a reference, not a feature commitment. Prioritize reliable background behavior and the existing release checks.
