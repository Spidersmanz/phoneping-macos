# Publishing the source

Source publication and a signed app download are separate milestones. Apple Developer approval is not needed to publish this source preview. It is needed for the intended Developer ID signing and notarization workflow.

## Local readiness

Before each initial push or release branch:

1. Review the complete change, including untracked files. Use the GitHub handle and no-reply email for commit authorship; keep personal contact details out of files, commits, tags, and branch names.
2. Run `python3 scripts/test-privacy.py` and `python3 scripts/check-privacy.py`. Confirm the local pre-push hook is enabled as described in [Contributing](../CONTRIBUTING.md). The hook inspects the exact pushed objects and destination names. It does not send any data.
3. Run the Swift tests and a release-configuration build from a clean source copy. Review the copy's file list before committing it. Do not copy build output, preferences, screenshots, credentials, or `.git` recovery files into a source archive.
4. Check the README and test matrix against observed results. Keep unsupported layouts and unverified configurations explicit.
5. Re-run the privacy check on the final commit. Push the intended branch explicitly; do not use a mirror push or publish all local refs.

The automated guard checks current files, the index, real commit objects, detached HEAD history, tags, and proposed remote names. Git replacement objects cannot conceal originals from the scan; local history grafts block the check. Pattern matching cannot recognize every location or device name, so manual review remains necessary. See [the privacy review](REPO-PRIVACY.md).

## GitHub setup

The source preview was published on October 13, 2026 at [Spidersmanz/phoneping-macos](https://github.com/Spidersmanz/phoneping-macos). Its initial GitHub-hosted `macos` check passed. Private vulnerability reporting, secret scanning, and push protection are enabled; workflow credentials default to read-only. The checklist below also applies to future setup changes; verify live settings rather than inferring them from this document.

- Approved repository: `Spidersmanz/phoneping-macos`. The maintainer confirmed this slug on October 12, 2026 and approved public source publication on October 13, 2026. Keep Lanza Studios Inc. credited. Use PhonePing as the working title, clearly marked as an experimental source preview; the final public app identity remains a decision before binary distribution.
- Description: “A small macOS menu bar app that plays a sound on your iPhone through Apple's Find My.” Suggested topics: `macos`, `swift`, `menu-bar`, `find-my`, `iphone`.
- Enable Issues and private vulnerability reporting. Verify **Security → Report a vulnerability** is available before inviting security reports. A SECURITY.md file alone does not enable the private channel. [GitHub's setup guide](https://docs.github.com/en/code-security/how-tos/report-and-fix-vulnerabilities/configure-vulnerability-reporting/configuring-private-vulnerability-reporting-for-a-repository).
- Enable available secret scanning and push protection. These complement the local privacy guard; they do not detect all personal data. [GitHub's push protection guide](https://docs.github.com/en/code-security/concepts/secret-security/push-protection).
- After the initial CI run, protect `main`: require pull requests, the passing `macos` check from GitHub Actions, and resolved review conversations; block force pushes and branch deletion. Verify the actual check name before selecting it.
- As a solo maintainer, use zero required approving reviews initially while retaining the PR and check requirements. Authors cannot approve their own PRs. Review contributor PRs yourself; add a required independent approval when another trusted maintainer is available. [GitHub's review rules](https://docs.github.com/en/pull-requests/how-tos/review-pull-requests/approving-a-pull-request-with-required-reviews).
- Keep Actions credentials read-only and do not give pull-request jobs Apple signing keys, notarization credentials, or a self-hosted Mac with a personal Find My session. This workflow only builds and tests synthetic fixtures on a hosted runner.
- Claude review is deferred until the maintainer has access again. The [review brief](REVIEW-BRIEF.md) is ready; no code has been sent for that review. Supply reviewed source and synthetic fixtures only when explicitly requested. A review comment does not replace maintainer judgment or live-device testing.

Do not publish the ad-hoc `dist` app as a ready-to-install release. No repository, remote, ruleset, or release is created by these instructions.

## Work independent of Apple approval

Use [Testing](TESTING.md) for the remaining live cases: existing/hidden/minimized Find My, foreground activation during a request, offline/pending results, already-playing state, incomplete lists, keyboard/VoiceOver access, and repeated-use recovery. Test only on the maintainer's own devices. Record outcomes without names, locations, or raw captures. Unsupported cases can remain documented limitations of the source preview; do not advertise them as verified.

The source is already guarded against duplicate names and detected partial lists. Supporting more layouts or languages requires evidence and tests, not a fallback to coordinates or a guessed target. Login launch and keyboard shortcuts can follow once the app's identity and installation are stable.

## Current window-state evidence

An initial existing-instance build 12 test rang the iPhone and preserved Find My, but it came forward. A controlled repeat, starting with another app in front and Find My open behind it, recorded playback, no activation, and preservation of the existing window; the maintainer confirmed ringing with Find My staying behind. The earlier behavior was not reproduced and its cause remains unproven. The cold-launch path has separate confirmed background and cleanup results. Hidden/minimized windows, Spaces/full-screen, activation races, and repeated-use reliability remain unverified; do not promise background behavior for every window state.

## Signed download gate

After Apple approval: inspect the organization certificate's public identity, settle the permanent bundle identifier and app name, build from a reviewed tag, sign and notarize, and inspect archive metadata. Test a clean installation and a successive signed update for permission and selection continuity. Complete the relevant live matrix before claiming broader compatibility. See [Distribution](DISTRIBUTION.md).

No public release or merge is automatic. The maintainer makes the final publication decision.
