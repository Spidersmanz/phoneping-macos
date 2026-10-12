import Foundation

/// Dismiss only the verified device sheet. Never activate Find My or touch Play Sound.
@MainActor struct FindMyQuitPreparation<Access: FindMyAccess> {
    let access: Access
    private typealias Element = Access.Element
    private enum InspectionError: Error { case unsupported, timedOut }

    func dismissDetails(in app: Access.Element, name: String,
                        isAllowed: @MainActor () -> Bool) async -> Bool {
        let deadline = access.now.advanced(by: .seconds(2))
        var closeAttempted = false
        do {
            for _ in 0..<8 {
                guard isAllowed() else { return false }
                try check(deadline)
                let all = try nodes(app, deadline: deadline)
                guard try text(app, "AXRole", deadline: deadline) == "AXApplication",
                      try all.contains(where: {
                          try ["AXWindow", "AXSheet"].contains(text($0, "AXRole", deadline: deadline))
                      }) else { return false }
                // An alert or unknown dialog must never be dismissed as device details.
                for node in all {
                    let role = try text(node, "AXRole", deadline: deadline)
                    let subrole = try text(node, "AXSubrole", deadline: deadline)
                    if ["AXAlert", "AXDialog"].contains(role) ||
                        (role == "AXWindow" && ["AXDialog", "AXSystemDialog"].contains(subrole)) { return false }
                }
                let sheets = try all.filter { try text($0, "AXRole", deadline: deadline) == "AXSheet" }
                if sheets.isEmpty { return isAllowed() }
                guard sheets.count == 1 else { return false }
                if !closeAttempted {
                    let contents = try nodes(sheets[0], deadline: deadline)
                    let labels = try contents.filter {
                        try text($0, "AXIdentifier", deadline: deadline) == "PrimaryLabel" ||
                            text($0, "AXDescription", deadline: deadline) == "PrimaryLabel" ||
                            text($0, "AXTitle", deadline: deadline) == "PrimaryLabel"
                    }
                    guard labels.count == 1 else { return false }
                    let names = try nodes(labels[0], deadline: deadline)
                        .filter { try text($0, "AXRole", deadline: deadline) == "AXStaticText" }
                        .map { node -> String in
                            let description = try text(node, "AXDescription", deadline: deadline)
                            let value = try text(node, "AXValue", deadline: deadline)
                            guard description.isEmpty || value.isEmpty || description == value else {
                                throw InspectionError.unsupported
                            }
                            return value.isEmpty ? description : value
                        }
                    guard names == [name] else { return false }
                    let playing = try contents.filter {
                        try text($0, "AXIdentifier", deadline: deadline) == "FMPlatterButton" &&
                            text($0, "AXRole", deadline: deadline) == "AXButton" &&
                            text($0, "AXDescription", deadline: deadline) == "Play Sound,Playing…"
                    }
                    let closes = try contents.filter {
                        try text($0, "AXIdentifier", deadline: deadline) == "Close" &&
                            text($0, "AXRole", deadline: deadline) == "AXButton"
                    }
                    guard playing.count == 1, closes.count == 1,
                          try access.number(closes[0], "AXEnabled") == 1,
                          try access.actions(closes[0]).contains("AXPress") else { return false }
                    try check(deadline)
                    guard isAllowed() else { return false }
                    closeAttempted = true
                    try access.perform("AXPress", on: closes[0])
                }
                // One close attempt only. Wait for the sheet to disappear before quitting.
                try await access.pause()
            }
        } catch { return false }
        return false
    }

    private func text(_ node: Element, _ key: String, deadline: ContinuousClock.Instant) throws -> String {
        try check(deadline)
        return try access.text(node, key) ?? ""
    }

    private func nodes(_ root: Element, deadline: ContinuousClock.Instant) throws -> [Element] {
        var queue: [(Element, Int)] = [(root, 0)]
        var seen = Set<Element>()
        var result: [Element] = []
        var cursor = 0
        while cursor < queue.count {
            try check(deadline)
            guard queue.count <= 700 else { throw InspectionError.unsupported }
            let (node, depth) = queue[cursor]
            cursor += 1
            guard seen.insert(node).inserted else { continue }
            result.append(node)
            if try text(node, "AXRole", deadline: deadline) == "AXImage" { continue }
            var children = try access.elements(node, "AXChildren") ?? []
            if depth == 0 {
                try check(deadline)
                children += try access.elements(node, "AXWindows") ?? []
                for key in ["AXFocusedWindow", "AXMainWindow"] {
                    try check(deadline)
                    if let window = try access.element(node, key) { children.append(window) }
                }
            }
            guard children.isEmpty || depth < 18 else { throw InspectionError.unsupported }
            queue += children.map { ($0, depth + 1) }
        }
        return result
    }

    private func check(_ deadline: ContinuousClock.Instant) throws {
        try Task.checkCancellation()
        guard access.now < deadline else { throw InspectionError.timedOut }
    }
}
