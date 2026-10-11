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
