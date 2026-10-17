import AppKit
import ApplicationServices
import PhonePingCore

/// Only this boundary talks to macOS. Tests supply synthetic elements and a clock.
protocol FindMyAccess: Sendable {
    associatedtype Element: Hashable & Sendable
    func application() async throws -> Element
    func runningApplication() async throws -> Element?
    func finish(_ outcome: FindMyRequestOutcome, selection: String?) async
    func operationReport() async -> FindMySessionReport?
    func text(_ element: Element, _ attribute: String) throws -> String?
    func number(_ element: Element, _ attribute: String) throws -> Int?
    func elements(_ element: Element, _ attribute: String) throws -> [Element]?
    func element(_ element: Element, _ attribute: String) throws -> Element?
    func frame(_ element: Element) throws -> CGRect?
    func actions(_ element: Element) throws -> [String]
    func actionDescription(_ action: String, on element: Element) throws -> String?
    func diagnosticValue(_ element: Element, _ attribute: String) throws -> DiagnosticValue
    func perform(_ action: String, on element: Element) throws
    func pause() async throws
    var now: ContinuousClock.Instant { get }
}

extension FindMyAccess {
    func finish(_ outcome: FindMyRequestOutcome) async { await finish(outcome, selection: nil) }
    func operationReport() async -> FindMySessionReport? { nil }
}

enum DiscoveryFailure: Error { case temporarilyUnavailable }

/// AX timeouts apply per reference; children read from an element don't inherit it.
/// Each wrapper sets its timeout, and elements read through it carry the same value.
struct AccessibilityElement: Hashable, @unchecked Sendable {
    let raw: AXUIElement
    let timeout: Float
    init(raw: AXUIElement, timeout: Float) {
        self.raw = raw
        self.timeout = timeout
        AXUIElementSetMessagingTimeout(raw, timeout)
    }
    func adopting(_ child: AXUIElement) -> Self { Self(raw: child, timeout: timeout) }
    static func == (lhs: Self, rhs: Self) -> Bool { CFEqual(lhs.raw, rhs.raw) }
    func hash(into hasher: inout Hasher) { hasher.combine(CFHash(raw)) }
}

// Session state is confined to MainActor; AX wrappers themselves are immutable.
final class NativeFindMyAccess: FindMyAccess, @unchecked Sendable {
    @MainActor private var session: FindMySession<NativeFindMyWorkspace>?
    @MainActor private var lastOperation: FindMySessionReport?
    var now: ContinuousClock.Instant { .now }
    func pause() async throws { try await Task.sleep(nanoseconds: 250_000_000) }

    @MainActor func runningApplication() async throws -> AccessibilityElement? {
        guard AXIsProcessTrusted() else { throw PingError.permission }
        guard let app = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.findmy").first else { return nil }
        return AccessibilityElement(raw: AXUIElementCreateApplication(app.processIdentifier), timeout: 0.25)
    }

    @MainActor func application() async throws -> AccessibilityElement {
        guard AXIsProcessTrusted() else { throw PingError.permission }
        guard session == nil else { throw PingError.busy }
        lastOperation = nil
        let opened = try await FindMySession.open(using: NativeFindMyWorkspace())
        session = opened
        return AccessibilityElement(raw: AXUIElementCreateApplication(opened.application.processIdentifier), timeout: 1)
    }

    @MainActor func finish(_ outcome: FindMyRequestOutcome, selection: String?) async {
        guard let session else { return }
        lastOperation = await session.finish(outcome) {
            guard let selection, session.mayDismissDetails else { return false }
            let app = AccessibilityElement(raw: AXUIElementCreateApplication(session.application.processIdentifier), timeout: 0.25)
            return await FindMyQuitPreparation(access: self).dismissDetails(
                in: app, name: selection,
                isAllowed: { session.mayDismissDetails })
        }
        self.session = nil
    }

    @MainActor func operationReport() async -> FindMySessionReport? { lastOperation }

    private func check(_ error: AXError, optional: Bool = true) throws -> Bool {
        if error == .success { return true }
        if optional && [.noValue, .attributeUnsupported, .actionUnsupported].contains(error) { return false }
        if error == .apiDisabled { throw PingError.permission }
        if [.cannotComplete, .invalidUIElement].contains(error) { throw DiscoveryFailure.temporarilyUnavailable }
        throw PingError.unsupportedInterface
    }

    private func value(_ element: AccessibilityElement, _ attribute: String) throws -> CFTypeRef? {
        var value: CFTypeRef?
        return try check(AXUIElementCopyAttributeValue(element.raw, attribute as CFString, &value)) ? value : nil
    }
    func text(_ element: AccessibilityElement, _ attribute: String) throws -> String? {
        guard let value = try value(element, attribute) else { return nil }
        guard let text = value as? String else { throw PingError.unsupportedInterface }
        return text
    }
    func diagnosticValue(_ element: AccessibilityElement, _ attribute: String) throws -> DiagnosticValue {
        DiagnosticValue.classify(try value(element, attribute))
    }
    func number(_ element: AccessibilityElement, _ attribute: String) throws -> Int? {
        guard let value = try value(element, attribute) else { return nil }
        guard let number = value as? NSNumber else { throw PingError.unsupportedInterface }
        return number.intValue
    }
    func elements(_ element: AccessibilityElement, _ attribute: String) throws -> [AccessibilityElement]? {
        guard let value = try value(element, attribute) else { return nil }
        guard let elements = value as? [AXUIElement] else { throw PingError.unsupportedInterface }
        return elements.map(element.adopting)
    }
    func element(_ element: AccessibilityElement, _ attribute: String) throws -> AccessibilityElement? {
        guard let value = try value(element, attribute) else { return nil }
        guard CFGetTypeID(value) == AXUIElementGetTypeID() else { throw PingError.unsupportedInterface }
        return element.adopting(value as! AXUIElement)
    }
    func frame(_ element: AccessibilityElement) throws -> CGRect? {
        guard let position = try value(element, kAXPositionAttribute),
              let size = try value(element, kAXSizeAttribute),
              CFGetTypeID(position) == AXValueGetTypeID(), CFGetTypeID(size) == AXValueGetTypeID() else { return nil }
        var point = CGPoint.zero
        var dimensions = CGSize.zero
        guard AXValueGetValue(position as! AXValue, .cgPoint, &point),
              AXValueGetValue(size as! AXValue, .cgSize, &dimensions) else { return nil }
        return CGRect(origin: point, size: dimensions)
    }
    func actions(_ element: AccessibilityElement) throws -> [String] {
        var names: CFArray?
        guard try check(AXUIElementCopyActionNames(element.raw, &names)) else { return [] }
        guard let result = names as? [String] else { throw PingError.unsupportedInterface }
        return result
    }
    func actionDescription(_ action: String, on element: AccessibilityElement) throws -> String? {
        var description: CFString?
        guard try check(AXUIElementCopyActionDescription(element.raw, action as CFString, &description)) else { return nil }
        return description as String?
    }
    func perform(_ action: String, on element: AccessibilityElement) throws {
        _ = try check(AXUIElementPerformAction(element.raw, action as CFString), optional: false)
    }
}
