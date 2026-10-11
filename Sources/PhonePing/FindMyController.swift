import AppKit
import ApplicationServices
import PhonePingCore

/// All accessibility work is isolated from the UI. No AppleScript, mouse coordinates,
/// private frameworks, network requests, account tokens, or Find My cache access.
actor FindMyController {
    private let bundleID = "com.apple.findmy"
    private var working = false

    func devices() async throws -> [String] {
        guard !working else { throw PingError.busy }
        working = true
        defer { working = false }
        let app = try await prepare()
        let rows = try deviceRows(app)
        return rows.map { DevicePolicy.name(from: text($0, kAXDescriptionAttribute)) }
            .filter { !$0.isEmpty }
    }

    func play(on name: String) async throws {
        guard !working else { throw PingError.busy }
        working = true
        defer { working = false }
        try DevicePolicy.validate(name)
        let app = try await prepare()

        var openedDetails = false
        var selectedRow = false
        // Retry discovery only. Once we invoke Play, never retry the side effect.
        for _ in 0..<20 {
            if selectedRow || openedDetails, let button = try verifiedSoundButton(in: app, name: name) {
                try perform(kAXPressAction as String, on: button)
                return
            }
            if openedDetails {
                try await Task.sleep(nanoseconds: 250_000_000)
                continue
            }
            let rows = try deviceRows(app)
            let names = rows.map { DevicePolicy.name(from: text($0, kAXDescriptionAttribute)) }
            let row = rows[try DevicePolicy.uniqueIndex(named: name, in: names)]
            // Verify the full name again in the details sheet before ringing.
            // The list label alone is ambiguous when a device name contains commas.
            if let details = namedAction(on: row, matching: { $0 == "Open Details" }) {
                try perform(details, on: row)
                openedDetails = true
            } else if !selectedRow && actions(row).contains(kAXPressAction as String) {
                try perform(kAXPressAction as String, on: row)
                selectedRow = true
                if try verifiedSoundButton(in: app, name: name) != nil { openedDetails = true }
            }
            try await Task.sleep(nanoseconds: 250_000_000)
        }
        throw PingError.unavailableAction
    }

    private func prepare() async throws -> AXUIElement {
        guard AXIsProcessTrusted() else { throw PingError.permission }
        let pid: pid_t = try await MainActor.run {
            guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) else {
                throw PingError.appUnavailable
            }
            if let running = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID).first {
                running.activate()
                return running.processIdentifier
            }
            // Launch asynchronously below when the application isn't running.
            _ = url
            return 0
        }
        let resolvedPID: pid_t
        if pid == 0 {
            resolvedPID = try await launch()
        } else {
            resolvedPID = pid
        }
        let app = AXUIElementCreateApplication(resolvedPID)
        AXUIElementSetMessagingTimeout(app, 1)

        for _ in 0..<16 {
            // Dismiss only a known device-details sheet, never a general alert.
            for sheet in try nodes(app).filter({ text($0, kAXRoleAttribute) == kAXSheetRole as String }) {
                let contents = try nodes(sheet)
                if contents.contains(where: { text($0, kAXIdentifierAttribute) == "FMPlatterButton" }),
                   let close = contents.first(where: { text($0, kAXIdentifierAttribute) == "Close" && text($0, kAXRoleAttribute) == kAXButtonRole as String }) {
                    try perform(kAXPressAction as String, on: close)
                }
            }
            let all = try nodes(app)
            // Selecting the actual tab keeps us out of People and Items.
            if let tab = all.first(where: { ["AXRadioButton", "AXTab"].contains(text($0, kAXRoleAttribute)) && text($0, kAXDescriptionAttribute) == "Devices" }) {
                if (attribute(tab, kAXValueAttribute) as? NSNumber)?.intValue != 1 {
                    try perform(kAXPressAction as String, on: tab)
                }
            } else if let menuItem = all.first(where: { text($0, kAXRoleAttribute) == kAXMenuItemRole as String && text($0, kAXTitleAttribute) == "Devices" }) {
                try perform(kAXPressAction as String, on: menuItem)
            }
            if (try? deviceRows(app))?.isEmpty == false { return app }
            try await Task.sleep(nanoseconds: 250_000_000)
        }
        throw PingError.unsupportedInterface
    }

    @MainActor private func launch() async throws -> pid_t {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.findmy") else {
            throw PingError.appUnavailable
        }
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true
        let app = try await NSWorkspace.shared.openApplication(at: url, configuration: configuration)
        return app.processIdentifier
    }

    private func deviceRows(_ app: AXUIElement) throws -> [AXUIElement] {
        let all = try nodes(app)
        // On the inspected Find My UI, the selected tab has AXValue = 1.
        let selectedDevices = all.contains {
            text($0, kAXDescriptionAttribute) == "Devices" &&
            (attribute($0, kAXValueAttribute) as? NSNumber)?.intValue == 1
        }
        guard selectedDevices else { throw PingError.unsupportedInterface }
        return all.filter { text($0, kAXIdentifierAttribute).hasPrefix("ListEntityRow") }
    }

    private func verifiedSoundButton(in app: AXUIElement, name: String) throws -> AXUIElement? {
        for sheet in try nodes(app).filter({ text($0, kAXRoleAttribute) == kAXSheetRole as String }) {
            let contents = try nodes(sheet)
            let primaryNames = try contents.filter { text($0, kAXDescriptionAttribute) == "PrimaryLabel" || text($0, kAXIdentifierAttribute) == "PrimaryLabel" || text($0, kAXTitleAttribute) == "PrimaryLabel" }
                .flatMap { try nodes($0) }
                .filter { text($0, kAXRoleAttribute) == kAXStaticTextRole as String }
                .map { text($0, kAXDescriptionAttribute) }
            let buttons = contents.filter {
                text($0, kAXIdentifierAttribute) == "FMPlatterButton" &&
                text($0, kAXRoleAttribute) == kAXButtonRole as String &&
                DevicePolicy.canPlay(expectedName: name, detailNames: primaryNames,
                                     buttonLabel: text($0, kAXDescriptionAttribute),
                                     enabled: (attribute($0, kAXEnabledAttribute) as? Bool) == true)
            }
            if buttons.count == 1 { return buttons[0] }
        }
        return nil
    }

    private func attribute(_ element: AXUIElement, _ name: String) -> CFTypeRef? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, name as CFString, &value) == .success else { return nil }
        return value
    }

    private func text(_ element: AXUIElement, _ name: String) -> String {
        attribute(element, name) as? String ?? ""
    }

    private func nodes(_ root: AXUIElement) throws -> [AXUIElement] {
        var result: [AXUIElement] = []
        var queue: [(AXUIElement, Int)] = [(root, 0)]
        var cursor = 0
        while cursor < queue.count {
            guard cursor < 700 else { throw PingError.unsupportedInterface }
            let (element, depth) = queue[cursor]
            cursor += 1
            if result.contains(where: { CFEqual($0, element) }) { continue }
            result.append(element)
            // Map content is irrelevant and may contain private location labels.
            if text(element, kAXRoleAttribute) != kAXImageRole as String {
                let attributes = depth == 0 ? [kAXChildrenAttribute, kAXWindowsAttribute] : [kAXChildrenAttribute]
                for key in attributes {
                    for child in try children(element, key: key) {
                        guard depth < 18 else { throw PingError.unsupportedInterface }
                        queue.append((child, depth + 1))
                    }
                }
            }
        }
        return result
    }

    private func children(_ element: AXUIElement, key: String) throws -> [AXUIElement] {
        var value: CFTypeRef?
        let error = AXUIElementCopyAttributeValue(element, key as CFString, &value)
        if error == .noValue || error == .attributeUnsupported { return [] }
        guard error == .success else { throw PingError.unsupportedInterface }
        return value as? [AXUIElement] ?? []
    }

    private func actions(_ element: AXUIElement) -> [String] {
        var names: CFArray?
        guard AXUIElementCopyActionNames(element, &names) == .success else { return [] }
        return names as? [String] ?? []
    }

    private func namedAction(on element: AXUIElement, matching predicate: (String) -> Bool) -> String? {
        let matches = actions(element).filter { action in
            var description: CFString?
            AXUIElementCopyActionDescription(element, action as CFString, &description)
            return predicate(action) || predicate(description as String? ?? "")
        }
        return matches.count == 1 ? matches[0] : nil
    }

    private func perform(_ action: String, on element: AXUIElement) throws {
        guard AXUIElementPerformAction(element, action as CFString) == .success else {
            throw PingError.actionFailed
        }
    }
}
