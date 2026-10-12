import AppKit
import SwiftUI

@MainActor final class AppDelegate: NSObject, NSApplicationDelegate {
    private let model = AppModel()
    private var statusItem: NSStatusItem!
    private var statusMenu: PhonePingMenu!
    private var settingsWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        configureAppMenu()
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusMenu = PhonePingMenu(model: model,
                                  showSettings: { [weak self] in self?.showSettings() },
                                  showAbout: { [weak self] in self?.showAbout() },
                                  quit: { NSApp.terminate(nil) })
        statusItem.menu = statusMenu.menu
        model.stateChanged = { [weak self] in self?.updateStatus() }
        model.revealSettings = { [weak self] in self?.showSettings() }
        updateStatus()
        if model.phoneName.isEmpty || !model.hasPermission { showSettings() }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showSettings()
        return true
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        model.checkPermission()
    }

    private func configureAppMenu() {
        let mainMenu = NSMenu()
        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu()
        for (title, action, key) in [
            ("About PhonePing", #selector(showAbout), ""),
            ("Settings…", #selector(showSettings), ",")
        ] {
            let item = NSMenuItem(title: title, action: action, keyEquivalent: key)
            item.target = self
            appMenu.addItem(item)
        }
        appMenu.addItem(.separator())
        let quit = NSMenuItem(title: "Quit PhonePing", action: #selector(quit), keyEquivalent: "q")
        quit.target = self
        appMenu.addItem(quit)
        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)

        let windowMenuItem = NSMenuItem(title: "Window", action: nil, keyEquivalent: "")
        let windowMenu = NSMenu(title: "Window")
        windowMenu.addItem(withTitle: "Close Window", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")
        windowMenuItem.submenu = windowMenu
        mainMenu.addItem(windowMenuItem)
        NSApp.mainMenu = mainMenu
    }

    private func updateStatus() {
        let symbol = model.busy ? "ellipsis.circle" : (model.needsAttention ? "exclamationmark.circle" : "iphone.radiowaves.left.and.right")
        let image = NSImage(systemSymbolName: symbol, accessibilityDescription: "PhonePing")
            ?? NSImage(systemSymbolName: "iphone", accessibilityDescription: "PhonePing")
        image?.isTemplate = true
        statusItem.button?.image = image
        let selection = model.phoneName.isEmpty ? "" : " — " + model.phoneName
        let status = model.statusSummary.isEmpty ? "" : "\n" + model.statusSummary
        statusItem.button?.toolTip = "PhonePing" + selection + status
        statusItem.button?.setAccessibilityLabel("PhonePing" + selection)
        statusItem.button?.setAccessibilityHelp("Open the menu to play a sound or change settings.")
        statusMenu.update()
    }

    @objc private func quit() { NSApp.terminate(nil) }

    @objc private func showAbout() {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.1.3"
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        let credits = NSAttributedString(
            string: "Play a sound on your device using Find My.\n\nAn open-source project by Lanza Studios Inc.\nMaintained by Spidersmanz.\nNot affiliated with Apple.",
            attributes: [.font: NSFont.systemFont(ofSize: NSFont.smallSystemFontSize),
                         .foregroundColor: NSColor.secondaryLabelColor,
                         .paragraphStyle: paragraph])
        var options: [NSApplication.AboutPanelOptionKey: Any] = [
            .applicationName: "PhonePing",
            .applicationVersion: "\(version) Preview",
            .credits: credits
        ]
        let appIcon = Bundle.main.url(forResource: "AppIcon", withExtension: "icns")
            .flatMap { NSImage(contentsOf: $0) }
        if let icon = appIcon ?? NSImage(systemSymbolName: "iphone.radiowaves.left.and.right", accessibilityDescription: nil) {
            icon.size = NSSize(width: 64, height: 64)
            options[.applicationIcon] = icon
        }
        NSApp.orderFrontStandardAboutPanel(options: options)
        NSApp.activate()
    }

    @objc private func showSettings() {
        model.checkPermission()
        if settingsWindow == nil {
            let controller = NSHostingController(rootView: SettingsView(model: model, showAbout: { [weak self] in self?.showAbout() }))
            let window = NSWindow(contentViewController: controller)
            window.title = "PhonePing Settings"
            window.styleMask = [.titled, .closable]
            window.isReleasedWhenClosed = false
            window.center()
            settingsWindow = window
        }
        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate()
        updateStatus()
    }
}

@main struct PhonePingApp {
    @MainActor static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        withExtendedLifetime(delegate) { app.run() }
    }
}
