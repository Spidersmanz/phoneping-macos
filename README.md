# PhonePing

**One click in your Mac’s menu bar to play a sound on your iPhone.**

PhonePing is a small native Mac app that operates Apple’s Find My app. Choose your phone once, then click the menu bar icon when you need to hear where it is.

**Early preview, not a public stable release.** Find My’s interface is not an automation contract. Compatibility must be tested for each macOS release. This project initially targets the English Find My interface observed on macOS 27.0.1. The deployment target is macOS 14, but that does not mean older versions have been verified.

## Privacy by design

- No account or Apple password entry in PhonePing.
- No network client, analytics, ads, updater, or developer server.
- No Find My cache, Keychain, browser cookie, or iCloud token access.
- Stores only your chosen device name in local macOS preferences.
- Uses the Apple Account already signed in to Find My.

The app runs locally. **Apple’s Find My service still uses the network to deliver the sound request.** This is not an offline Bluetooth ping. Accessibility is a powerful macOS permission; read [PRIVACY.md](PRIVACY.md) for exactly what the app does with it.

## Build and run

You need a Mac and Xcode or its Command Line Tools with Swift 5.9 or later. There are no third-party package dependencies.

```sh
bash scripts/build.sh
open dist/PhonePing.app
```

The build is for the current Mac’s architecture and is signed locally with an ad-hoc signature. It is not notarized for public distribution. **Do not disable Gatekeeper or other macOS security protections.** For the preview, build from source on your own Mac.

1. Make sure your iPhone is listed in Apple’s Find My app on this Mac.
2. Give the phone a unique name without commas in iPhone Settings → General → About → Name. Allow time for Find My to update.
3. Open PhonePing and use **Open Permission Settings** to grant permission yourself. On macOS 27 this permission is called **Device Control and Data Access**; older versions call it **Accessibility**. You may need to add `dist/PhonePing.app` with the + button.
4. Click **Refresh**, choose your iPhone, and click **Play Sound** to test it.
5. Close the settings window. Left-click the menu bar icon to request a sound. Right-click or Option-click for settings and Quit.

Keep the app at a stable path. Moving or rebuilding a locally signed app can require granting Accessibility again. To start it at login, add the built app through macOS Login Items; PhonePing does not modify login settings itself.

## What to expect

Find My may appear while PhonePing operates it. The app reports that it requested a sound, not that your iPhone has actually made one. If your phone is offline, Find My can queue the sound until it reconnects. Silence it with an iPhone volume or power button. See [Apple’s Play Sound instructions](https://support.apple.com/en-ca/guide/findmy-mac/fmm48b093e33/mac).

PhonePing stops rather than guessing if names are duplicated, your selected phone is absent, or the expected controls cannot be identified. It verifies the full name in the phone’s details before pressing Play Sound. It never selects a default first device, uses fixed screen coordinates, or invokes Erase, Lost Mode, or Remove.

## Development

```sh
bash scripts/test.sh
bash scripts/build.sh
```

The tests exercise exact device selection and sound-action safeguards. Automated tests do not ring a real phone. Manual validation is documented in [docs/TESTING.md](docs/TESTING.md).

| Location | Purpose |
| --- | --- |
| `Sources/PhonePing` | Native menu bar UI and Find My accessibility adapter |
| `Sources/PhonePingCore` | Device selection and action validation |
| `Tests/PhonePingCoreTests` | Safety regression tests |
| `docs/ARCHITECTURE.md` | Design decisions and research |
| `docs/ROADMAP.md` | Small, staged release plan |

Contributions are welcome. Start with [CONTRIBUTING.md](CONTRIBUTING.md). No Apple device, account, or location data should be included in issues or test fixtures.

## License and affiliation

[MIT](LICENSE). PhonePing is an independent project and is not affiliated with or endorsed by Apple. Apple, iPhone, macOS, and Find My are Apple trademarks.
