# Cleanup after playback — build 11

October 11, 2026. Local preview 0.1.3 build 11.

## Problem and change

Build 10 rang the intended iPhone and stayed behind the foreground window, confirmed by the maintainer. Its diagnostic recorded Normal quit requested, but Find My remained running. Apple documents that `NSRunningApplication.terminate()` reports whether the request was sent; the process may not have exited.

During follow-up inspection, closing the device-details sheet and then using normal keyboard Quit exited Find My. This suggested that the modal sheet could be preventing cleanup. Build 11 tests that approach in the actual sound flow.

For a newly launched Find My that the user has not activated, after playback is observed:

1. Recheck the exact device name and Playing status in the details sheet.
2. Require one enabled Close control and press it once. Unknown dialogs or ambiguous controls stop cleanup.
3. Wait up to two seconds for the sheet to disappear. Recheck activation and cancellation before continuing.
4. Request a normal quit once, then check for process exit for up to two seconds.

The diagnostic reports confirmed exit separately from an unconfirmed quit request. No force quit, focus change, keyboard event synthesis, second sound request, or background polling is added. Existing visible, user-activated, and pending/uncertain sessions remain protected. The activation observer stays in place until cleanup ends, then is removed. A previously hidden session is returned to hidden without dismissing its details.

An in-flight Accessibility call can extend the dismissal budget by its native timeout. The selected name is used transiently for verification and is not included in the diagnostic or newly persisted.

## Validation

107 synthetic tests pass in staging and the project: 12 policy, 14 model/menu, 45 automation/diagnostic, 12 quit-preparation, and 24 lifecycle tests. Release compilation, packaging, and strict signature verification pass.

New tests cover verified sheet dismissal with no sound call, changed/conflicting names, disabled/ambiguous close controls, unknown/multiple sheets and dialogs, missing window data, an ignored or failed close with no retry, activation before/after dismissal, ignored/delayed quit, cancellation, observer removal, and reentrant cleanup. Existing tests retain protection for old/unknown process ownership and existing/pending sessions.

## Live result

Build 11 is installed with build 10 retained for rollback. After the maintainer refreshed the existing permission, PhonePing showed Allowed. One cold-launch Settings request observed playback, identified a new Find My process, recorded no activation, and reported Normal quit confirmed. Independent process checks found Find My absent before and after the request. The maintainer confirmed that the iPhone kept ringing after Find My closed and that Find My stayed behind the current window.

Exactly one sound action was sent. The read-only diagnostic did not relaunch Find My or send another request. Its temporary report was dismissed without saving or copying personal data. This verifies continued ringing, foreground preservation, and process cleanup in one local test; repeated use and other window states remain separate release checks.

## Repeat confirmation, October 12

One additional cold-launch request observed playback and Normal quit confirmed, with no activation recorded. The maintainer confirmed that the phone rang and Find My stayed behind. This adds a second successful build 11 cold-launch observation; it does not complete the hidden/existing-window or sustained-use test matrix. A five-minute idle sample in the same PhonePing process followed after the maintainer closed Settings; see [PERFORMANCE.md](PERFORMANCE.md).

## Sources

- [Apple: normal quit requests](https://developer.apple.com/documentation/appkit/nsrunningapplication/terminate%28%29?changes=_5).
- [Apple: observing process termination](https://developer.apple.com/documentation/appkit/nsrunningapplication/isterminated?changes=__6_8).
