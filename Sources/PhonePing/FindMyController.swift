import Foundation
import PhonePingCore

enum FindMySoundResult: Equatable, Sendable { case submitted, alreadyPlaying }

protocol FindMyService: Sendable {
    func devices() async throws -> [String]
    func play(on name: String) async throws -> FindMySoundResult
    func diagnose(selection: String) async throws -> String
}

typealias FindMyController = FindMyAutomation<NativeFindMyAccess>
extension FindMyAutomation where Access == NativeFindMyAccess {
    init() { self.init(access: NativeFindMyAccess()) }
}

/// Discovery retries are bounded. Play Sound is invoked at most once per request.
actor FindMyAutomation<Access: FindMyAccess>: FindMyService {
    typealias Element = Access.Element
    private let access: Access
    private var working = false
    private var deadline = ContinuousClock.now
    init(access: Access) { self.access = access }

    func diagnose(selection: String) async throws -> String {
        try begin()
        defer { working = false }
        let lastOperation = await access.operationReport().map { $0.text + "\n\n" } ?? ""
        // Inspection must not use prepare(), which navigates and can dismiss sheets.
        guard let app = try await access.runningApplication() else {
            return lastOperation + "Find My is not running. Open it to inspect its current controls."
        }
        return try lastOperation + FindMyDiagnostic(access: access).report(app: app, selection: selection)
    }

    func devices() async throws -> [String] {
        try begin()
        defer { working = false }
        do {
            let app = try await prepare()
            let result = try deviceRows(app).map(\.name)
            await access.finish(.notSubmitted)
            return result
        } catch {
            await access.finish(.notSubmitted)
            throw error
        }
    }

    @discardableResult func play(on name: String) async throws -> FindMySoundResult {
        try DevicePolicy.validate(name)
        try begin()
        defer { working = false }
        var outcome = FindMyRequestOutcome.notSubmitted
        do {
            let result = try await requestSound(on: name, outcome: &outcome)
            await access.finish(outcome, selection: name)
            return result
        } catch {
            await access.finish(outcome, selection: name)
            throw error
        }
    }

    private func requestSound(on name: String, outcome: inout FindMyRequestOutcome) async throws -> FindMySoundResult {
        let app = try await prepare()
        var openedDetails = false
        var selectedRow = false
        for _ in 0..<20 {
            try checkTime()
            do {
                let all = try nodes(app)
                try rejectUnexpectedDialogs(in: all)
                let sheets = try all.filter { try text($0, "AXRole") == "AXSheet" }
                guard sheets.count <= 1 else { throw PingError.unsupportedInterface }
                if let sheet = sheets.first {
                    // Find My can replace the exposed list with its modal details.
                    // Only follow a sheet after selecting a uniquely verified row.
                    guard openedDetails || selectedRow else { throw PingError.unsupportedInterface }
                    if try exposesDeviceList(all) {
                        let rows = try deviceRows(in: all)
                        _ = try DevicePolicy.uniqueIndex(named: name, in: rows.map(\.name))
                    }
                    if let state = try verifiedSoundState(in: sheet, name: name) {
                        try checkTime()
                        guard case let .ready(button) = state else {
                            outcome = .alreadyPlaying
                            return .alreadyPlaying
                        }
                        // A timeout may follow a successful action. No discovery catch may retry this.
                        outcome = .submitted
                        do { try access.perform("AXPress", on: button) }
                        catch { throw PingError.requestUncertain }
                        if await waitForPlayback(in: app, name: name) { outcome = .playing }
                        return .submitted
                    }
                } else {
                    let rows = try deviceRows(in: all)
                    let row = rows[try DevicePolicy.uniqueIndex(named: name, in: rows.map(\.name))].element
                    if !openedDetails {
                        let actions = try access.actions(row)
                        let details = try actions.filter {
                            if $0 == "Open Details" { return true }
                            return try access.actionDescription($0, on: row) == "Open Details"
                        }
                        guard details.count <= 1 else { throw PingError.unsupportedInterface }
                        if let action = details.first {
                            try access.perform(action, on: row)
                            openedDetails = true
                        } else if !selectedRow && actions.contains("AXPress") {
                            try access.perform("AXPress", on: row)
                            selectedRow = true
                        }
                    }
                }
            } catch DiscoveryFailure.temporarilyUnavailable {
                // Re-read the tree; never fall back to a cached row or a screen coordinate.
            }
            try await access.pause()
        }
        throw PingError.unavailableAction
    }

    private func begin() throws {
        guard !working else { throw PingError.busy }
        working = true
        deadline = access.now.advanced(by: .seconds(10))
    }

    private func prepare() async throws -> Element {
        let app = try await access.application()
        var closeAttempted = false
        for _ in 0..<16 {
            try checkTime()
            do {
                let all = try nodes(app)
                try rejectUnexpectedDialogs(in: all)
                let sheets = try all.filter { try text($0, "AXRole") == "AXSheet" }
                guard sheets.count <= 1 else { throw PingError.unsupportedInterface }
                if let sheet = sheets.first {
                    if !closeAttempted {
                        let contents = try nodes(sheet)
                        let names = try detailNames(in: contents)
                        let sounds = try soundButtons(in: contents)
                        let closes = try contents.filter {
                            try text($0, "AXIdentifier") == "Close" && text($0, "AXRole") == "AXButton"
                        }
                        guard names.count == 1, !names[0].trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                              sounds.count == 1, closes.count == 1,
                              try access.number(closes[0], "AXEnabled") == 1,
                              try access.actions(closes[0]).contains("AXPress") else { throw PingError.unsupportedInterface }
                        try checkTime()
                        // A failed action may still have taken effect. Never send it twice.
                        closeAttempted = true
                        try access.perform("AXPress", on: closes[0])
                    }
                    try await access.pause()
                    continue
                }
                let tabs = try all.filter {
                    try ["AXRadioButton", "AXTab"].contains(text($0, "AXRole")) && text($0, "AXDescription") == "Devices"
                }
                guard tabs.count <= 1 else { throw PingError.unsupportedInterface }
                guard let tab = tabs.first else { throw DiscoveryFailure.temporarilyUnavailable }
                if try access.number(tab, "AXValue") != 1 {
                    try access.perform("AXPress", on: tab)
                    try await access.pause()
                    continue
                }
                _ = try deviceRows(app)
                return app
            } catch DiscoveryFailure.temporarilyUnavailable { }
            try await access.pause()
        }
        throw PingError.unsupportedInterface
    }

    private func deviceRows(_ app: Element) throws -> [(element: Element, name: String)] {
        try deviceRows(in: nodes(app))
    }

    private func exposesDeviceList(_ all: [Element]) throws -> Bool {
        try all.contains {
            let identifier = try text($0, "AXIdentifier")
            return try identifier.hasPrefix("ListEntityRow") ||
                (["AXRadioButton", "AXTab"].contains(text($0, "AXRole")) && text($0, "AXDescription") == "Devices")
        }
    }

    private func deviceRows(in all: [Element]) throws -> [(element: Element, name: String)] {
        let tabs = try all.filter {
            try ["AXRadioButton", "AXTab"].contains(text($0, "AXRole")) && text($0, "AXDescription") == "Devices"
        }
        guard tabs.count == 1, try access.number(tabs[0], "AXValue") == 1 else {
            throw DiscoveryFailure.temporarilyUnavailable
        }
        let cards = try all.filter { try text($0, "AXIdentifier") == "CardContainerView" }
        guard cards.count == 1 else { throw PingError.unsupportedInterface }
        let contents = try nodes(cards[0])
        let rows = try contents.filter { try text($0, "AXIdentifier").hasPrefix("ListEntityRow") }
        guard !rows.isEmpty else { throw DiscoveryFailure.temporarilyUnavailable }

        // Support the inspected, fully expanded list only. A clipped/scrolling list
        // cannot establish uniqueness: an unexposed row might have the same name.
        guard let cardFrame = try access.frame(cards[0]), usable(cardFrame) else { throw PingError.incompleteList }
        for node in contents {
            let role = try text(node, "AXRole")
            if ["AXScrollArea", "AXScrollBar", "AXTable", "AXOutline"].contains(role) {
                throw PingError.incompleteList
            }
        }
        let windows = try all.filter { try text($0, "AXRole") == "AXWindow" }
        guard windows.count == 1, let windowFrame = try access.frame(windows[0]),
              usable(windowFrame), windowFrame.insetBy(dx: -1, dy: -1).contains(cardFrame) else { throw PingError.incompleteList }
        for row in rows {
            guard let frame = try access.frame(row), usable(frame),
                  cardFrame.insetBy(dx: -1, dy: -1).contains(frame) else { throw PingError.incompleteList }
        }
        return try rows.map { row in
            let name = DevicePolicy.name(from: try text(row, "AXDescription"))
            guard !name.isEmpty else { throw PingError.incompleteList }
            return (row, name)
        }
    }

    private func usable(_ frame: CGRect) -> Bool {
        [frame.origin.x, frame.origin.y, frame.width, frame.height].allSatisfy(\.isFinite) && frame.width > 0 && frame.height > 0
    }

    /// A separate bounded read after submission. Never navigates or presses again.
    private func waitForPlayback(in app: Element, name: String) async -> Bool {
        deadline = access.now.advanced(by: .seconds(5))
        for _ in 0..<20 {
            do {
                try checkTime()
                let all = try nodes(app)
                try rejectUnexpectedDialogs(in: all)
                let sheets = try all.filter { try text($0, "AXRole") == "AXSheet" }
                guard sheets.count == 1 else { return false }
                if case .playing? = try verifiedSoundState(in: sheets[0], name: name) { return true }
                try await access.pause()
            } catch { return false }
        }
        return false
    }

    private func verifiedDetails(in sheet: Element, name: String) throws -> [Element] {
        let contents = try nodes(sheet)
        guard try detailNames(in: contents) == [name] else { throw PingError.detailsChanged }
        return contents
    }

    private func detailNames(in contents: [Element]) throws -> [String] {
        let labels = try contents.filter {
            try text($0, "AXDescription") == "PrimaryLabel" || text($0, "AXIdentifier") == "PrimaryLabel" || text($0, "AXTitle") == "PrimaryLabel"
        }
        guard labels.count == 1 else { throw PingError.unsupportedInterface }
        return try nodes(labels[0]).filter { try text($0, "AXRole") == "AXStaticText" }
            .map { try staticText($0) }
    }

    private enum SoundState { case ready(Element), playing }

    private func verifiedSoundState(in sheet: Element, name: String) throws -> SoundState? {
        let buttons = try soundButtons(in: verifiedDetails(in: sheet, name: name))
        guard buttons.count <= 1 else { throw PingError.unsupportedInterface }
        guard let button = buttons.first else { return nil }
        if try text(button, "AXDescription") == "Play Sound,Playing…" { return .playing }
        guard try DevicePolicy.canPlay(expectedName: name, detailNames: [name],
                                       buttonLabel: text(button, "AXDescription"),
                                       enabled: access.number(button, "AXEnabled") == 1) else { return nil }
        return .ready(button)
    }

    private func soundButtons(in contents: [Element]) throws -> [Element] {
        try contents.filter {
            try text($0, "AXIdentifier") == "FMPlatterButton" && text($0, "AXRole") == "AXButton" &&
                ["Play,Off", "Play Sound,Off", "Play Sound,Playing…"].contains(text($0, "AXDescription"))
        }
    }

    private func rejectUnexpectedDialogs(in all: [Element]) throws {
        for node in all {
            let role = try text(node, "AXRole")
            let subrole = try text(node, "AXSubrole")
            if ["AXAlert", "AXDialog"].contains(role) ||
                (role == "AXWindow" && ["AXDialog", "AXSystemDialog"].contains(subrole)) {
                throw PingError.unsupportedInterface
            }
        }
    }

    private func staticText(_ element: Element) throws -> String {
        let description = try text(element, "AXDescription")
        let value = try text(element, "AXValue")
        guard description.isEmpty || value.isEmpty || description == value else { throw PingError.detailsChanged }
        return value.isEmpty ? description : value
    }

    private func text(_ element: Element, _ key: String) throws -> String {
        try checkTime()
        return try access.text(element, key) ?? ""
    }

    private func nodes(_ root: Element) throws -> [Element] {
        var result: [Element] = []
        var visited = Set<Element>()
        var queue: [(Element, Int)] = [(root, 0)]
        var cursor = 0
        while cursor < queue.count {
            try checkTime()
            guard queue.count <= 700 else { throw PingError.unsupportedInterface }
            let (element, depth) = queue[cursor]
            cursor += 1
            guard visited.insert(element).inserted else { continue }
            result.append(element)
            // Skip map contents, including location labels.
            let role = try text(element, "AXRole")
            if role == "AXImage" { continue }
            var relationships = ["AXChildren"]
            if depth == 0 { relationships.append("AXWindows") }
            if depth == 0 {
                // A focused sheet may not appear in the application's window array.
                for key in ["AXFocusedWindow", "AXMainWindow"] {
                    if let window = try access.element(element, key) { queue.append((window, depth + 1)) }
                }
            }
            for key in relationships {
                for child in try access.elements(element, key) ?? [] {
                    guard depth < 18 else { throw PingError.unsupportedInterface }
                    queue.append((child, depth + 1))
                }
            }
        }
        return result
    }

    private func checkTime() throws {
        try Task.checkCancellation()
        guard access.now < deadline else { throw PingError.discoveryTimedOut }
    }
}
