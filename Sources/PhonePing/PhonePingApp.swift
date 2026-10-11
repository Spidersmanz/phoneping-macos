import AppKit
import SwiftUI

@MainActor final class AppDelegate: NSObject, NSApplicationDelegate {
    private let model = AppModel()
    private var statusItem: NSStatusItem!
    private var settingsWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        let mainMenu = NSMenu()
        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu()
        let settings = NSMenuItem(title: "Settings…", action: #selector(showSettings), keyEquivalent: ",")
        settings.target = self
        appMenu.addItem(settings)
        appMenu.addItem(.separator())
        let quitItem = NSMenuItem(title: "Quit PhonePing", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        appMenu.addItem(quitItem)
        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)
        NSApp.mainMenu = mainMenu
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.target = self
            button.action = #selector(clicked)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
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
        model.hasPermission = AXIsProcessTrusted()
    }

    private func updateStatus() {
        let symbol = model.busy ? "ellipsis.circle" : (model.failed ? "iphone.badge.exclamationmark" : "iphone.radiowaves.left.and.right")
        let image = NSImage(systemSymbolName: symbol, accessibilityDescription: "PhonePing")
            ?? NSImage(systemSymbolName: "iphone", accessibilityDescription: "PhonePing")
        image?.isTemplate = true
        statusItem.button?.image = image
        let label = model.phoneName.isEmpty ? "Set up PhonePing" : "Play sound on \(model.phoneName)"
        statusItem.button?.toolTip = model.busy ? "Requesting a sound…" : label + " · Right-click for settings"
        statusItem.button?.setAccessibilityLabel(label)
        statusItem.button?.setAccessibilityHelp("Click to play a sound. Right-click or Option-click for settings.")
    }

    @objc private func clicked() {
        if NSApp.currentEvent?.type == .rightMouseUp || NSApp.currentEvent?.modifierFlags.contains(.option) == true {
            showMenu()
        } else { model.ping() }
    }

    private func showMenu() {
        let menu = NSMenu()
        let ping = NSMenuItem(title: "Play Sound", action: #selector(play), keyEquivalent: "")
        ping.target = self
        ping.isEnabled = model.ready
        menu.addItem(ping)
        menu.addItem(.separator())
        for (title, action) in [("Settings…", #selector(showSettings)), ("Open Find My", #selector(openFindMy)), ("Quit PhonePing", #selector(quit))] {
            let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
            item.target = self
            menu.addItem(item)
        }
        menu.autoenablesItems = false
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    @objc private func play() { model.ping() }
    @objc private func quit() { NSApp.terminate(nil) }
    @objc private func openFindMy() {
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.findmy") {
            NSWorkspace.shared.openApplication(at: url, configuration: .init())
        }
    }

    @objc private func showSettings() {
        if settingsWindow == nil {
            let controller = NSHostingController(rootView: SettingsView(model: model))
            let window = NSWindow(contentViewController: controller)
            window.title = "PhonePing"
            window.styleMask = [.titled, .closable, .miniaturizable]
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
