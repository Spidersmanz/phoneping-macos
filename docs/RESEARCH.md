# Existing tools and project naming

Research date: October 11, 2026. This is a review of publicly discoverable projects and their documentation, not a claim that every competing tool has been found. The alternatives below have not been installed or independently audited.

The [research follow-up](RESEARCH-FOLLOWUP.md) records the subsequent source review, current build 11 evidence, organization signing decision, and prioritized release work.

## Findings

Related solutions already exist. Searches did not identify a verified standalone native Mac menu bar app with this project's exact intended combination: one saved iPhone, the Mac's existing Find My session, no separate Apple sign-in, and no screenshot capture. That is an opportunity to test, not evidence of exclusive novelty.

| Tool | Documented behavior | Difference from this project |
| --- | --- | --- |
| [Apple Find My](https://support.apple.com/en-ca/guide/findmy-mac/fmm48b093e33/mac) | Plays a sound on a selected device; offline requests can wait for reconnection. | Built-in baseline; this project reduces the repeated steps to a menu bar click. |
| [Find My Devices for Raycast](https://github.com/Visual-Studio-Coder/find-my-devices-raycast) | Lists eligible Apple devices and sends Play Sound requests. Requires Raycast, a Python helper, and a separate local Apple Account sign-in. | A launcher extension with a saved iCloud web session, rather than a dedicated menu bar app using the already signed-in Find My app. |
| [findmy-cli](https://github.com/omarshahine/findmy-cli) | Its `ring` command opens Find My and clicks Play Sound. The project documents Accessibility and Screen Recording permissions for this action, using screenshots and OCR. | Close technical precedent. Its interface is a command-line tool with broader location-query features. Our current adapter uses accessibility elements without screenshots. |
| [Near Lock](https://nearlock.me/features) | Its Mac menu bar and iPhone companion apps provide proximity locking and other features. The vendor advertises pinging an iPhone connected to the Mac and Bluetooth Low Energy communication. | A broader companion-app product. Its advertised ping is relevant prior work; present OS compatibility and maintenance were not verified. |
| [PhonePing: Clap Alert](https://apps.apple.com/us/app/phoneping-clap-alert/id6761522571?platform=ipad) | An iPhone/iPad app that advertises sound triggered by clapping or calling a nickname. | Different interaction, but an existing use of the proposed name in the same phone-finding category. |

The value of this project should be simplicity and inspectable behavior: a small native utility that does one useful job. We should acknowledge related work and avoid claims such as “the first,” “nothing else exists,” “zero privacy risk,” or guaranteed instant delivery.

[CommandLatch](https://commandlatch.dev/) is an adjacent Mac menu bar product for remote actions. Its documentation labels iPhone pinging “coming soon” and describes account/backend delivery, so it is not counted as a verified available ping feature. Recheck before making a public comparison.

The Raycast project documents use of private iCloud web endpoints and a locally retained web session. It also states that account, device, and analytics data are not sent to its author. Our different implementation avoids a second sign-in and stored web session; that does not establish that the other project is unsafe. The CLI documents returning focus after activating Find My. Build 11 has one verified cold-launch result with continued ringing, foreground preservation, and cleanup; other window states still need live evidence.

The useful product distinction to validate is a native menu bar action using the existing Find My account, without a companion phone app, Screen Recording permission, device history, or another runtime. Those are specific design choices, not a ranking of overall quality.

The app's local execution does not make Find My's delivery offline. Apple still handles the network request. Accessibility permission is broad even though this code targets only Find My. Build 11 rang from a nonactivating cold launch, confirmed Find My exited, and the maintainer reported continued ringing with Find My staying behind. Earlier builds did not consistently clean up. Existing hidden and other window states remain separate checks; see [TESTING.md](TESTING.md).

## Naming recommendation

**Proposed repository name: `ping-iphone-mac`.** It states the action, target device, and platform. A repository name can be descriptive without also being the final app brand.

Suggested repository description:

> A small macOS menu bar app that plays a sound on your iPhone through Apple's Find My. No separate sign-in, analytics, or developer server.

“PhonePing” was a working name. Given the existing PhonePing app, choose a different public name before launch. The proposed repository name did not surface an exact matching project in this search, but that is not a guarantee of name availability. Final repository ownership and app branding remain maintainer decisions.

Keep the current local app name and path stable while completing the permission and real-device checks. Decide the public name and permanent bundle identifier before signed distribution, then update the app, build scripts, and documentation together.

## Search scope

Searches covered general web results, GitHub projects, and App Store listings using combinations of “Mac,” “iPhone,” “menu bar,” “menubar,” “Find My,” “Play Sound,” and “ping.” Exact-name searches included “PhonePing,” “ping-iphone,” “ring-my-iphone,” and “ping-iphone-mac.” Primary project documentation and Apple's own pages support the comparison above.

## Apple Watch and Control Center follow-up

The [Watch and Mac controls comparison](WATCH-CONTROLS-RESEARCH.md) records Apple’s documented ping flow and the macOS 26+ public control APIs. The maintainer chose the existing menu bar interface as the single entry point, so a separate Control Center integration is out of scope. The research is retained as a reference; Find My remains the delivery mechanism.
