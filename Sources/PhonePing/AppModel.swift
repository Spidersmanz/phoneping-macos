import AppKit
import ApplicationServices
import SwiftUI
import PhonePingCore

@MainActor final class AppModel: ObservableObject {
    @Published var phoneName: String {
        didSet { UserDefaults.standard.set(phoneName, forKey: "phoneName") }
    }
    @Published var devices: [String] = []
    @Published var hasPermission = AXIsProcessTrusted()
    @Published var busy = false
    @Published var message = ""
    @Published var failed = false
    var stateChanged: (() -> Void)?
    var revealSettings: (() -> Void)?
    private let controller = FindMyController()
    private var permissionTimer: Timer?

    init() {
        phoneName = UserDefaults.standard.string(forKey: "phoneName") ?? ""
        permissionTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.hasPermission = AXIsProcessTrusted() }
        }
    }

    var ready: Bool { hasPermission && !phoneName.isEmpty && !busy }
    var uniqueDevices: [String] { Array(Set(devices)).sorted() }
    func isDuplicate(_ name: String) -> Bool { devices.filter { $0 == name }.count > 1 }

    func openPermissions() {
        message = "Enable PhonePing under Privacy & Security → Device Control and Data Access (called Accessibility on older macOS versions). Reopen the app if permission isn’t detected."
        failed = false
        // The OS owns the permission choice; never change TCC or settings ourselves.
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    func refresh() {
        guard !busy else { return }
        begin("Reading devices from Find My…")
        Task {
            do {
                devices = try await controller.devices()
                finish("Choose your iPhone below.")
            } catch { finish(error.localizedDescription, failure: true) }
            revealSettings?()
        }
    }

    func ping() {
        hasPermission = AXIsProcessTrusted()
        guard !busy else { return }
        guard hasPermission && !phoneName.isEmpty else { revealSettings?(); return }
        begin("Requesting a sound…")
        Task {
            do {
                try await controller.play(on: phoneName)
                finish("Sound requested in Find My. An offline phone will ring when it reconnects.")
            } catch {
                finish(error.localizedDescription, failure: true)
                revealSettings?()
            }
        }
    }

    func forget() {
        guard !busy else { return }
        phoneName = ""
        devices = []
        message = "Saved phone removed from this Mac."
        failed = false
        stateChanged?()
    }

    private func begin(_ message: String) {
        busy = true
        failed = false
        self.message = message
        stateChanged?()
    }

    private func finish(_ message: String, failure: Bool = false) {
        busy = false
        failed = failure
        self.message = message
        stateChanged?()
    }
}
