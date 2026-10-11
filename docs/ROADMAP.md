# Release plan

## 1. Local proof

- [x] Inspect Find My's controls without accessing account tokens or private caches.
- [x] Build a native menu bar app with setup and explicit permission handling.
- [x] Test exact matching, duplicate names, and allowed sound actions.
- [ ] Verify device enumeration and one sound request through PhonePing on a real iPhone.
- [ ] Verify repeated use, restarting Find My, offline handling, and revoked permission.

The live checks are the release gate. A successful build alone does not prove the feature works.

## 2. Small open-source preview

- [x] MIT license, privacy explanation, contribution guidance, PR/issue templates, and CI configuration.
- [ ] Finish and record the manual test matrix.
- [ ] Review the code and privacy claims; optionally obtain a Claude review of the diff.
- [ ] Confirm repository owner and project name with the maintainer.
- [ ] Create the GitHub repository, enable private security reporting, and require reviewed PRs and passing checks on main.
- [ ] Publish source with explicit compatibility limits after maintainer approval.

## 3. Downloadable release

- [ ] Test more supported macOS versions and both processor architectures before claiming support.
- [ ] Choose a permanent reverse-DNS bundle identifier.
- [ ] Arrange a Developer ID signing identity and notarization.
- [ ] Build from a reviewed tag, verify signature, notarize, and publish checksums.
- [ ] Add a clean screenshot with fictional device data and a short setup guide.

## Later, only if useful

Keyboard shortcut, optional launch at login, localized Find My adapters, and better confirmation from observable Find My state. Keep the single-button interaction and privacy boundary intact.
