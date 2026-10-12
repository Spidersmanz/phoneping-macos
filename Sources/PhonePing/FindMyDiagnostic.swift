import Foundation
import PhonePingCore

/// Only these fixed labels can enter a report. Unknown values never use description.
struct DiagnosticValue: Equatable, Sendable {
    let summary: String
    private init(_ summary: String) { self.summary = summary }

    static func classify(_ value: CFTypeRef?) -> Self {
        guard let value else { return Self("absent") }
        if CFGetTypeID(value) == CFBooleanGetTypeID() {
            return Self((value as? Bool) == true ? "boolean true" : "boolean false")
        }
        if let number = value as? NSNumber {
            if number == 0 { return Self("number 0") }
            if number == 1 { return Self("number 1") }
            return Self("other number")
        }
        if let string = value as? String {
            let known = Set(["Play Sound", "Play", "Off", "On", "Play Sound,Off", "Play Sound,On", "Play,Off", "Play,On",
                             "AXButton", "AXCheckBox", "AXStaticText", "AXSheet", "AXWindow", "AXGroup"])
            if known.contains(string) { return Self("text: " + string) }
            let normalized = string.split(separator: ",", omittingEmptySubsequences: false)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.joined(separator: ",")
            if known.contains(normalized) { return Self("text with whitespace: " + normalized) }
            return Self("other text (omitted)")
        }
        return Self("other type (omitted)")
    }
}

/// An explicit, bounded inspection. No navigation, action, file, logging or network code.
struct FindMyDiagnostic<Access: FindMyAccess> {
    let access: Access

    func report(app: Access.Element, selection: String) throws -> String {
        let deadline = access.now.advanced(by: .seconds(5))
        var visited = Set<Access.Element>()
        var queue: [(Access.Element, Int)] = [(app, 0)]
        var cursor = 0
        var limited = false
        var failures = 0
        var roles: [String: Int] = [:]
        var relationships: [String: Int] = [:]
        var controls: [String] = []
        var headers: [String] = []
        var selectedRows: [String] = []

        func checkTime() throws {
            try Task.checkCancellation()
            guard access.now < deadline else { throw PingError.discoveryTimedOut }
        }
        func read<T>(_ body: () throws -> T) throws -> T? {
            try checkTime()
            do { return try body() }
            catch PingError.permission { throw PingError.permission }
            catch is CancellationError { throw CancellationError() }
            catch { failures += 1; return nil }
        }
        func text(_ node: Access.Element, _ key: String) throws -> String {
            try read { try access.text(node, key) ?? "" } ?? ""
        }
        func append(_ children: [Access.Element], depth: Int) {
            guard depth <= 18 else { limited = limited || !children.isEmpty; return }
            for child in children {
                guard queue.count < 700 else { limited = true; return }
                queue.append((child, depth))
            }
        }
        let knownRoles: Set<String> = ["AXApplication", "AXWindow", "AXSheet", "AXGroup", "AXButton", "AXStaticText", "AXImage", "AXRadioButton", "AXTab", "AXCheckBox", "AXScrollArea", "AXScrollBar", "AXTable", "AXOutline"]
        do {
            while cursor < queue.count {
                try checkTime()
                let (node, depth) = queue[cursor]
                cursor += 1
                guard visited.insert(node).inserted else { continue }
                let role = try text(node, "AXRole")
                roles[knownRoles.contains(role) ? role : "other", default: 0] += 1
                // Do not read map-image labels or descend into their contents.
                if role == "AXImage" { continue }
                let identifier = try text(node, "AXIdentifier")
                if identifier == "FMPlatterButton" {
                    var attributes: [String] = []
                    for key in ["AXRole", "AXDescription", "AXTitle", "AXValue", "AXEnabled"] {
                        let value = try read { try access.diagnosticValue(node, key) }
                        attributes.append("  \(key): \(value?.summary ?? "unreadable")")
                    }
                    controls.append(attributes.joined(separator: "\n"))
                }
                if try identifier == "PrimaryLabel" || text(node, "AXDescription") == "PrimaryLabel" || text(node, "AXTitle") == "PrimaryLabel" {
                    let children = try read { try access.elements(node, "AXChildren") ?? [] } ?? []
                    for child in children where try text(child, "AXRole") == "AXStaticText" {
                        let description = try text(child, "AXDescription")
                        let value = try text(child, "AXValue")
                        headers.append("  description matches selection: \(!selection.isEmpty && description == selection)\n  value matches selection: \(!selection.isEmpty && value == selection)")
                    }
                }
                if !selection.isEmpty && identifier.hasPrefix("ListEntityRow"),
                   DevicePolicy.name(from: try text(node, "AXDescription")) == selection {
                    let actions = try read { try access.actions(node) } ?? []
                    var details = 0
                    for action in actions {
                        if action == "Open Details" { details += 1 }
                        else if try textAction(action, node: node) == "Open Details" { details += 1 }
                    }
                    selectedRows.append("  action count: \(actions.count)\n  AXPress present: \(actions.contains("AXPress"))\n  Open Details matches: \(details)")
                }
                var keys = depth == 0 ? ["AXChildren", "AXWindows"] : ["AXChildren"]
                if ["AXWindow", "AXSheet"].contains(role) { keys.append("AXContents") }
                for key in keys {
                    let children = try read { try access.elements(node, key) ?? [] } ?? []
                    if !children.isEmpty { relationships[key, default: 0] += children.count }
                    append(children, depth: depth + 1)
                }
                if depth == 0 {
                    for key in ["AXFocusedWindow", "AXMainWindow", "AXFocusedUIElement"] {
                        if let window = try read({ try access.element(node, key) }) ?? nil {
                            relationships[key, default: 0] += 1
                            append([window], depth: depth + 1)
                        }
                    }
                }
            }
        } catch PingError.discoveryTimedOut { limited = true }

        // Action descriptions are compared in memory and never included verbatim.
        func textAction(_ action: String, node: Access.Element) throws -> String {
            try read { try access.actionDescription(action, on: node) ?? "" } ?? ""
        }
        var lines = ["PhonePing control diagnostic (format 1)", "Read-only; no sound requested.",
                     "Scan complete: \(!limited && failures == 0)", "Visited controls: \(visited.count)", "Read failures: \(failures)", "", "Roles:"]
        lines += roles.keys.sorted().map { "  \($0): \(roles[$0]!)" }
        lines += ["", "Relationships:"] + relationships.keys.sorted().map { "  \($0): \(relationships[$0]!)" }
        lines += ["", "Matching device rows: \(selectedRows.count)"] + selectedRows
        lines += ["", "Details headers: \(headers.count)"] + headers
        lines += ["", "Detail action controls: \(controls.count)"]
        for (index, control) in controls.enumerated() { lines += ["Control \(index + 1):", control] }
        return lines.joined(separator: "\n")
    }
}
