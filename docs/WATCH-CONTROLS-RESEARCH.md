# Apple Watch ping and Mac controls

October 11, 2026. Research reference; a separate Control Center integration is out of scope by maintainer decision. No Control Center feature has been implemented.

## Recommendation

Use the Apple Watch interaction as a reference for one clear action on a previously chosen device. Keep the native menu bar icon as the single entry point, with Play Sound, Settings, and recovery in its menu. The maintainer explicitly declined maintaining both menu bar and Control Center interfaces. The alternative below is retained as technical research, not planned work.

## What Apple documents

| Surface | Documented interaction | Relevance to PhonePing |
| --- | --- | --- |
| Apple Watch | Open Control Center with the side button, then tap Ping iPhone. Holding the button also flashes the phone. Supported models can offer Precision Finding. | A single-purpose control with a known target. The normal path still has an opening action followed by an explicit ping action. |
| Find My on Mac | Select a device and choose Play. Online delivery follows a delay and can last about two minutes; offline requests wait for reconnection. | This is our delivery mechanism. A successful local action cannot establish that the phone was heard. |
| Third-party Mac controls | Mac apps can provide controls in Control Center and directly in the menu bar. | A supported route to a more Watch-like surface, beyond the existing menu. |

Sources: [Apple Watch ping](https://support.apple.com/en-ca/guide/watch/apddd5a326d2/watchos), [Find My Play Sound](https://support.apple.com/en-ca/guide/findmy-mac/fmm48b093e33/mac), and [WWDC25: What’s new in widgets, controls section](https://developer.apple.com/videos/play/wwdc2025/278/).

The installed macOS SDK marks `StaticControlConfiguration` and `ControlWidgetButton` as available on macOS 26.0 and later. This corroborates the documented platform support; it is not an installed-extension test. The existing app can retain its older deployment target while a future control is version-gated.

## Interaction findings

- **Current menu:** clicking the icon opens the standard menu; the first action names the selected device. Keep Settings accessible in that menu. This matches the Watch’s short two-action flow while making the Mac target visible.
- **Researched alternative, out of scope:** a button labeled “Ping iPhone,” with a recognizable system phone symbol and a “Play Sound” action hint. A button fits this request; an on/off toggle would imply a persistent state we cannot confirm. Apple distinguishes action buttons from state toggles in its [controls guidance](https://developer.apple.com/design/human-interface-guidelines/controls/).
- **Feedback:** show progress only during a request, prevent concurrent submissions, and report “Sound requested” after Find My accepts the action. Do not display “Ringing” based on local submission alone.
- **Setup:** choose the phone once in PhonePing. A missing selection or permission should lead to setup. Opening a menu or displaying a control must not scan devices or send a sound.
- **Scope:** retain the current credential-free Find My adapter. Flashing, distance arrows, a short Watch-style tone, and Bluetooth/offline delivery are not established capabilities of this adapter.

## Integration questions if the decision is revisited

The control supplies an entry point, not an iPhone sound API. Apple’s runtime documentation says a control’s intent in a Widget extension runs in that extension in the background. That does not establish access to PhonePing’s Accessibility grant. A prototype must demonstrate execution in the intended app process with the same permission checks and one-request guard. [Apple: App Intent runtime behavior](https://developer.apple.com/documentation/appintents/configuring-the-runtime-behavior-of-your-app-intents?changes=__3).

Apple also documents `allowedExecutionTargets`, which can restrict intent execution to the main app. The installed SDK marks it macOS 27+, and the retrieved documentation labels it beta. Treat it as a version-specific candidate requiring a real test, not a proven macOS 26 solution. [Apple: allowedExecutionTargets](https://developer.apple.com/documentation/appintents/appintent/allowedexecutiontargets?changes=_5).

Any future proposal would need to prove:

1. It invokes the existing guarded action from the intended process without another Accessibility grant or a helper service.
2. It works when PhonePing is running and closed, with permission allowed and revoked, while preserving the user’s foreground app where possible.
3. Widget display and refresh do no Find My discovery, polling, or network work.
4. Rapid clicks across both surfaces still produce one in-flight request; uncertain submissions are never retried automatically.
5. Packaging, signing, keyboard/VoiceOver access, and combined idle resource use remain suitable for a small utility.

These are constraints on the researched alternative, not an active prototype checklist. The standard menu is the chosen interface.

## Evidence and limits

- **Documented:** Watch interaction, Find My delivery behavior, Mac control placement, and App Intent process considerations above.
- **Locally observed:** build 6’s read-only diagnostic found a matching details header and enabled sound control while the device list was absent. Build 7 submitted a sound request with Find My visible, and the maintainer confirmed the intended iPhone rang. Its hidden-window request stopped before submission; background navigation remains unresolved. See TESTING.md in the project.
- **Bounded search:** Apple’s developer documentation and Find My developer page did not reveal a documented Mac API for the Watch’s nearby ping mechanism. The [Find My developer program](https://developer.apple.com/find-my/) describes accessory integration. This search does not prove that no other interface exists.
- **REA:** the skill was consulted. No REA tools were connected in this session and `rea` was not found on the shell path. No Watch binary or Watch runtime was inspected. These are documentation, SDK, source, and existing live-UI findings, not REA decompilation evidence. The Watch’s internal transport remains unknown here.

These documentation updates do not change build 7 or its signing identity.
