import AppKit

/// A standard menu keeps the sound action explicit and keyboard-accessible.
@MainActor final class PhonePingMenu: NSObject, NSMenuDelegate {
    let menu = NSMenu()
    private let model: AppModel
    private let showSettings: () -> Void
    private let showAbout: () -> Void
    private let quit: () -> Void
    private let soundItem = NSMenuItem()
    private let statusItem = NSMenuItem()

    init(model: AppModel, showSettings: @escaping () -> Void,
         showAbout: @escaping () -> Void, quit: @escaping () -> Void) {
        self.model = model
        self.showSettings = showSettings
        self.showAbout = showAbout
        self.quit = quit
        super.init()
        menu.delegate = self
        menu.autoenablesItems = false
        soundItem.target = self
        soundItem.action = #selector(playSound)
        statusItem.isEnabled = false
        menu.addItem(soundItem)
        menu.addItem(statusItem)
        menu.addItem(.separator())
        add("Settings…", action: #selector(openSettings), key: ",")
        add("Open Find My", action: #selector(openFindMy))
        add("About PhonePing", action: #selector(openAbout))
        menu.addItem(.separator())
        add("Quit PhonePing", action: #selector(quitApp), key: "q")
        update()
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        model.checkPermission()
        update()
    }

    func update() {
        let name = model.phoneName
        let shortName = name.count > 36 ? String(name.prefix(35)) + "…" : name
        soundItem.title = name.isEmpty ? "Play Sound" : "Play Sound on \(shortName)"
        // Keep the target complete for assistive technology even when the visible title is shortened.
        soundItem.setAccessibilityLabel(name.isEmpty ? "Play Sound" : "Play Sound on \(name)")
        soundItem.toolTip = name.isEmpty ? nil : "Play Sound on \(name)"
        soundItem.isEnabled = model.ready
        statusItem.title = model.statusSummary
        statusItem.toolTip = model.statusText
        statusItem.isHidden = model.statusSummary.isEmpty
    }

    private func add(_ title: String, action: Selector, key: String = "") {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: key)
        item.target = self
        menu.addItem(item)
    }

    @objc private func playSound() { model.ping() }
    @objc private func openSettings() { showSettings() }
    @objc private func openFindMy() { model.openFindMy() }
    @objc private func openAbout() { showAbout() }
    @objc private func quitApp() { quit() }
}
