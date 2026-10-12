# Contributing

PhonePing should remain small: a dependable Play Sound button that uses Apple’s own Find My app. Discuss large changes in an issue before implementing them. Compatibility fixes, accessibility improvements, clearer setup, and reproducible bug reports are especially useful.

1. Create a branch for one change.
2. Keep account, device, and location data out of code, fixtures, logs, and screenshots.
3. Run `bash scripts/test.sh` and `bash scripts/build.sh`.
4. For changes to the Find My adapter, complete the relevant cases in `docs/TESTING.md` on your own device. Record macOS version and interface language, without private labels.
5. Open a PR describing the problem, resulting behavior, validation, and remaining limitations.
6. Wait for the maintainer’s approval. No automatic merging.

Claude or another assistant can provide an additional code review before approval. Give it the diff, synthetic test data, and `AGENTS.md`. Ask it to focus on wrong-device selection, accidental non-sound actions, privacy regressions, permission handling, and honest success reporting. An AI review is not a substitute for maintainer review or a real-device test. No AI review service is connected by default.

Do not add iCloud login flows, reverse-engineered Apple endpoints, analytics, automatic account discovery, hidden daemons, or broad permissions to fix an automation problem. If Apple changes its UI, fail safely and document the compatibility gap.

Be considerate in discussions. Explain the behavior you observed, avoid personal criticism, and help newcomers reproduce issues.

## Before your first commit

Use your GitHub no-reply email for commit attribution. Configure it for this repository, then enable the local push check:

```sh
git config --local user.name "YOUR_GITHUB_HANDLE"
git config --local user.email "YOUR_GITHUB_NOREPLY_ADDRESS"
git config --local core.hooksPath .githooks
python3 scripts/check-privacy.py
```

Get your exact no-reply address from GitHub Settings → Emails. The local check examines current files, staged content, actual commit history including detached HEAD, and tags. The push hook also checks destination branch/tag names. Local Git replacements cannot hide original objects; history grafts block review. It rejects non-public email addresses, common credential formats, personal machine paths, generated/private files, and unreviewed binaries. It does not upload files or print matched values. Run `python3 scripts/test-privacy.py` after changing this check.

The push hook is local to each clone and must be enabled there. Do not bypass a failed check to publish. Review the final diff manually; pattern matching cannot recognize every device name, location, identifier, or secret. CI repeats the check after upload and is not a substitute for the local check. See [repository privacy](docs/REPO-PRIVACY.md).

For repository settings and the separate signed-download gate, see [Publishing](docs/PUBLISHING.md).
