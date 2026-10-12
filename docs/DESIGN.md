# Interface review

October 11, 2026 · Local preview 0.1.3 build 10

## Direction

A small Mac utility should look and behave like part of the desktop. Use standard AppKit menus and windows, SwiftUI form controls, system typography, semantic colors, and SF Symbols where they clarify a control. The project is independent software; following Apple’s guidance is not Apple certification or endorsement.

## Changes

| Previous design | Current design | Reason |
| --- | --- | --- |
| Menu icon immediately rang the device; settings required a secondary click | A normal click opens a native menu; Play Sound names the target | Makes the target and settings visible and reduces accidental requests |
| Large app title, custom teal icon tile, tagline and repeated footer | Window titled PhonePing Settings; version and credits in About | Gives space to the actual controls |
| Large full-width sound button and custom permission card | System-sized controls in a grouped native form | Follows the user’s system appearance and standard focus/pressed states |
| Long error sentences in the menu | Brief status in the menu; full explanation in settings | Keeps the menu readable without discarding recovery guidance |
| Long combined help disclosure | Separate Using PhonePing, Privacy, and Troubleshooting rows; one expanded at a time | Makes guidance easier to find and scan |
| Minimize button in a fixed settings window | Close-only fixed settings window; Command-W support | Follows the settings-window convention |
| Required permission followed disabled device controls | Setup shows the permission step and any saved selection; device controls appear after access is allowed | Shows the next available action while keeping Clear Selection available |
| Refresh shown before any devices are loaded | Find Devices for initial setup; Refresh afterward | Names the first action more clearly |
| Clear Selection competed with Play Sound | Borderless Clear Selection; normal Play Sound button | Keeps the everyday action prominent |
| Empty discovery repeated the setup prompt | No devices found, with a specific Find My recovery step | Explains why there is nothing to select |
| Diagnostic controls preceded everyday help | Usage, delivery, and local privacy come first; troubleshooting follows | Keeps technical recovery secondary |
| Permission instructions could outlive the permission error | Clear the obsolete state when access is restored | Prevents contradictory feedback |

## Writing rules

- Name the action: Play Sound, Refresh, Clear Selection, Open Find My.
- Use one term for each action. Keep Apple’s product name Find My intact.
- Use short status headings and a specific recovery step. Avoid slogans, celebratory success copy, filler, jargon, and claims of seamless or instant behavior.
- Say “Sound requested in Find My.” A successful UI action is not evidence that a device was heard.
- Do not claim Find My access is narrowly scoped by macOS. Explain the broad permission before the user grants it.
- State what is stored and who delivers the request. Avoid “full privacy,” “zero risk,” “Apple-approved,” or unmeasured performance claims.
- Keep developer implementation details in documentation unless they help someone grant permission or recover from a failure.

## Validation

The latest source passes 87 synthetic tests and release compilation. A separate preview with fictional data was checked in light/dark appearances, setup, empty/duplicate lists, long names, busy/uncertain states, expanded help, and diagnostic Escape dismissal. These changes are now packaged in build 10; build 9 is retained for rollback. Permission recovery, saved selection, expanded troubleshooting, and diagnostic Escape dismissal were checked in the installed app. See [UI-POLISH.md](UI-POLISH.md) for scope and remaining checks.

Automated menu/model checks verify that opening the menu neither discovers devices nor submits sound, and that permission revocation disables Play Sound. The manual checklist is in TESTING.md. Visual polish does not close the background-delivery, complete-device-enumeration, VoiceOver, performance, signing, or OS-compatibility release gates.

Do not add optional direct-click mode, a dashboard, notifications, animations, or more settings until the core flow is reliable. Keep the existing event-driven design and no-dependency policy.

## Sources

- [Apple: Writing](https://developer.apple.com/design/human-interface-guidelines/writing): plain language, clear action labels, and consistent terms.
- [Apple: Menus](https://developer.apple.com/design/human-interface-guidelines/menus): descriptive commands and purposeful grouping.
- [Apple: Settings](https://developer.apple.com/design/human-interface-guidelines/settings): standard Settings command, Command-comma, window naming, and disabled minimize/maximize controls.
- [Apple: Design principles](https://developer.apple.com/design/human-interface-guidelines/design-principles): focus, hierarchy, concise language, and iterative refinement.

## Watch reference, October 11 follow-up

The icon → Play Sound menu flow has the same short opening-then-action structure as Apple Watch’s Control Center → Ping flow. The maintainer chose the menu bar as the single entry point. Keep the selected device visible in the action and Settings in the same menu. Do not add a separate Control Center integration. The [Watch comparison](WATCH-CONTROLS-RESEARCH.md) is retained as research only.
