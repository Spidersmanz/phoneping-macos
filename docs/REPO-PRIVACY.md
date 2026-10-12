# Repository publication privacy

October 11, 2026. Local check before the first push. No remote is configured and nothing was published during this review.

## October 12 publication follow-up

A clean copy containing 62 eligible source files passed all 120 Swift tests, 23 privacy regressions, release packaging, strict signature verification, plist validation, and shell checks. No build products, personal captures, preferences, or Git recovery files were copied into the source candidate. GitHub-hosted CI has not run because the repository has not been created.

Four new regressions first reproduced omissions in the publication guard: a private push-destination name, a detached commit absent from ordinary refs, an original object hidden by a Git replacement, and an ancestor hidden by a local graft. Those cases now fail the guard. Additional cases cover external grafts, an unborn repository, and allowing removal of an already-private remote name without printing it. The guard reads real objects with replacement substitution disabled and blocks grafted history.

The actual checkout's no-reply identity and executable push hook were verified. Its one reachable commit and 24 historical blobs pass the guard and a separate check for known personal identifiers. The 62 current publication candidates also pass both checks. These results do not certify arbitrary future files or all possible private text; review the final commit before pushing.

The source and diagnostic paths were reviewed for credential access, saved UI text, external requests, idle work, and sound retries. No new app-runtime change was needed in this publication pass. Build 12 remains installed with its existing permission. Public credits use the GitHub handle and company name. Nothing has been uploaded and no remote is configured.

See [Publishing](PUBLISHING.md) for repository settings, solo-maintainer review rules, and the separate signed-download gate. The earlier review below records the initial cleanup and explains the local recovery history.

## Public identity

Credit Lanza Studios Inc. and the verified GitHub handle [Spidersmanz](https://github.com/Spidersmanz). Keep personal and work email addresses out of source, documentation, fixtures, and commit metadata.

The sole unpublished commit originally used a personal email. Its author and committer now use the GitHub handle and ID-based no-reply address. The file tree and uncommitted changes were preserved. Repository-local Git settings apply that identity to future commits; other repositories and account login settings were not changed.

The earlier commit remains in local Git recovery history. Normal pushes do not include reflogs or unreachable objects. No backup branch or tag points to it, and the configured push hook was checked against an explicit attempt to push that old object: it was blocked. Do not publish a whole folder archive containing `.git` or local recovery files.

## Local guard

`python3 scripts/check-privacy.py` checks reachable commits, author/committer identities, commit messages, tags, filenames, ref names, staged files, and current nonignored files. The pre-push hook also checks the actual objects being pushed, including detached commits. It reports categories without printing matched values or private filenames, and makes no network requests.

The guard blocks common credential formats, non-public email addresses, absolute personal-machine paths, private/generated file types, unreviewed binary files, symlinks, and submodules. GitHub no-reply identities and reserved example email domains are allowed. Ignore rules exclude builds, captures, diagnostics, logs, credentials, databases, editor state, and local assistant folders. Forced additions are still checked.

The hook is enabled in this checkout through the repository-local `core.hooksPath`. New clones must enable it as described in [Contributing](../CONTRIBUTING.md). CI repeats the check with full history, but CI happens after upload and cannot prevent the initial disclosure. Never bypass a failed local check to publish.

## Reviewed app icon — October 12

`Resources/AppIcon.icns` is the only approved binary source asset. Its exact SHA-256 is recorded in the publication guard. It was built from the two editable vectors in `Resources/Artwork`; all ten representations were decoded by macOS ImageIO and matched the rendered source pixels. The container contains only PNG representations, with no separate metadata section, and its input PNGs contain no text or EXIF metadata. No personal captures or account data were used.

The exception removes only the unreviewed-binary finding for that exact path and hash. Email, credential, path, history, index, and other checks still run. Changed bytes, another path, and an unreviewed staged version remain blocked. All 16 privacy tests pass, including four new reviewed-asset regression cases. No public upload was performed.

## Evidence and limits

- Reachable history contains one commit and 24 historical file versions. Current files and staged content pass the local check.
- Manual review found no personal device names, locations, account details, personal captures, or absolute home paths in publication candidates. Example contact/location text in tests is explicitly fictional.
- All 12 privacy regression tests pass, including deleted historical data, staged-only secrets, forced ignored files, private tag/commit identities, machine paths, private filenames, symlinks, binary captures, and detached-object push checks.
- The pre-push entry point passes for the current repository and rejects the original commit identity without performing a push. Release compilation passes after changing public credits.
- The installed build 11 app was preserved. Its binary contains no home-directory or personal temporary-directory prefixes, nor the checked personal/work email domains. Its older About credit remains local; the next packaged build will use the public handle.

Pattern checks cannot identify every secret, device name, location, or personal identifier. Review the final diff before publication and manually review any proposed screenshot or binary asset before adding a narrow, documented exception. Release downloads need their own review; excluded build products are not approved for publication by this source check.

GitHub account settings can also keep web-authored commits private and block command-line pushes exposing a personal email. Those account-wide settings were not changed here. See [GitHub commit email settings](https://docs.github.com/en/account-and-profile/how-tos/email-preferences/setting-your-commit-email-address) and [no-reply address formats](https://docs.github.com/en/account-and-profile/reference/email-addresses-reference).
