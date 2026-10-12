import AppKit
import ApplicationServices
import SwiftUI
import PhonePingCore

@MainActor final class AppModel: ObservableObject {
    @Published var phoneName: String {
        didSet {
            guard phoneName != oldValue else { return }
            preferences.set(phoneName, forKey: "phoneName")
            message = ""
            summary = ""
            permissionIssue = false
            failed = false
            stateChanged?()
        }
    }
    @Published private(set) var devices: [String] = []
    @Published private(set) var hasLoadedDevices = false
    @Published private(set) var hasPermission: Bool
    @Published private(set) var busy = false
    @Published private(set) var message = ""
    @Published private(set) var summary = ""
    @Published private(set) var failed = false
    @Published private(set) var diagnosticReport = ""
    var stateChanged: (() -> Void)?
    var revealSettings: (() -> Void)?
    private let controller: any FindMyService
    private let preferences: UserDefaults
    private let permissionCheck: () -> Bool
    private var operation: Task<Void, Never>?
    private var permissionIssue = false

    init(preferences: UserDefaults = .standard,
         controller: any FindMyService = FindMyController(),
         permissionCheck: @escaping () -> Bool = { AXIsProcessTrusted() }) {
        self.preferences = preferences
        self.controller = controller
        self.permissionCheck = permissionCheck
        phoneName = preferences.string(forKey: "phoneName") ?? ""
        hasPermission = permissionCheck()
    }

    var selectionIssue: PingError? {
        DevicePolicy.selectionIssue(named: phoneName, in: hasLoadedDevices ? devices : nil)
    }
    var ready: Bool { hasPermission && !busy && selectionIssue == nil }
    var uniqueDevices: [String] { Array(Set(devices)).sorted() }
    func count(named name: String) -> Int { devices.filter { $0 == name }.count }
    func isDuplicate(_ name: String) -> Bool { count(named: name) > 1 }

    var statusSummary: String {
        if busy { return summary }
        if !hasPermission { return "Permission required" }
        if failed { return summary }
        if phoneName.isEmpty {
            return hasLoadedDevices && devices.isEmpty ? AppText.noDevicesTitle : "Choose a device in Settings"
        }
        if let issue = selectionIssue { return issue.title }
        return summary
    }

    var statusText: String {
        if busy { return message }
        if !hasPermission { return AppText.permissionInstructions }
        if failed { return message }
        if phoneName.isEmpty {
            return hasLoadedDevices && devices.isEmpty ? AppText.noDevicesMessage : "Choose a device in Settings."
        }
        if let issue = selectionIssue { return issue.localizedDescription }
        return message
    }

    var needsAttention: Bool { !hasPermission || (!phoneName.isEmpty && selectionIssue != nil) || failed }

    func checkPermission() {
        let current = permissionCheck()
        guard hasPermission != current else { return }
        hasPermission = current
        if current && permissionIssue {
            message = ""
            summary = ""
            failed = false
            permissionIssue = false
        }
        stateChanged?()
    }

    func openPermissions() {
        message = AppText.permissionInstructions
        summary = "Permission required"
        permissionIssue = true
        failed = false
        stateChanged?()
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    func openFindMy() {
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.findmy") {
            NSWorkspace.shared.openApplication(at: url, configuration: .init())
        }
    }

    func refresh() {
        checkPermission()
        guard !busy else { return }
        guard hasPermission else { revealSettings?(); return }
        begin("Refreshing devices…")
        operation = Task {
            do {
                devices = try await controller.devices()
                hasLoadedDevices = true
                finish(devices.isEmpty ? AppText.noDevicesMessage : "",
                       summary: devices.isEmpty ? AppText.noDevicesTitle : "")
            } catch {
                // Do not keep presenting an old snapshot as freshly verified.
                devices = []
                hasLoadedDevices = false
                finish(error)
            }
        }
    }

    func ping() {
        checkPermission()
        guard !busy else { return }
        guard hasPermission && !phoneName.isEmpty else { revealSettings?(); return }
        if let issue = selectionIssue {
            finish(issue)
            return
        }
        let requestedName = phoneName
        begin("Requesting sound…")
        operation = Task {
            do {
                switch try await controller.play(on: requestedName) {
                case .submitted:
                    finish("An offline device may play the sound when it reconnects.", summary: "Sound requested in Find My")
                case .alreadyPlaying:
                    finish("Find My reports that a sound is already playing on this device.", summary: "Sound already playing")
                }
            } catch {
                finish(error)
            }
        }
    }

    func forget() {
        guard !busy else { return }
        phoneName = ""
        devices = []
        hasLoadedDevices = false
        finish("", summary: "")
    }

    func runDiagnostic() {
        checkPermission()
        guard !busy else { return }
        guard hasPermission else { revealSettings?(); return }
        let selection = phoneName
        let previous = (message, summary, failed, permissionIssue)
        diagnosticReport = ""
        begin("Checking Find My…")
        operation = Task {
            var permissionLost = false
            do { diagnosticReport = try await controller.diagnose(selection: selection) }
            catch {
                let known = error as? PingError
                diagnosticReport = known?.localizedDescription ?? "The diagnostic couldn’t finish. No sound was requested."
                permissionLost = known == .permission
            }
            if permissionLost { finish(PingError.permission) }
            else {
                permissionIssue = previous.3
                finish(previous.0, summary: previous.1, failure: previous.2)
            }
        }
    }

    func clearDiagnostic() { diagnosticReport = "" }

    // Tests await the actual operation; they never launch Find My or play a sound.
    func waitForOperation() async { await operation?.value }

    private func begin(_ message: String) {
        busy = true
        permissionIssue = false
        failed = false
        self.message = message
        summary = message
        stateChanged?()
    }

    private func finish(_ message: String, summary: String, failure: Bool = false) {
        busy = false
        failed = failure
        self.summary = summary
        self.message = message
        stateChanged?()
    }

    private func finish(_ error: Error) {
        let knownError = error as? PingError
        permissionIssue = knownError == .permission
        if permissionIssue { hasPermission = false }
        finish(knownError?.localizedDescription ?? "Check Find My before trying again.",
               summary: knownError?.title ?? "Couldn’t complete the request", failure: true)
    }

}
