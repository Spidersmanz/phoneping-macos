import AppKit
import PhonePingCore

enum FindMyRequestOutcome: Equatable, Sendable {
    case notSubmitted, submitted, playing, alreadyPlaying

    var invocationAttempted: Bool { self == .submitted || self == .playing }
    var playbackObserved: Bool { self == .playing || self == .alreadyPlaying }
}

enum FindMyCleanupResult: String, Sendable {
    case noProcess = "No process available"
    case alreadyExited = "Process already exited"
    case keptActive = "Kept open: activated during operation"
    case keptPending = "Kept open: playback not observed"
    case quitConfirmed = "Normal quit confirmed"
    case quitUnconfirmed = "Normal quit sent; exit not confirmed"
    case quitDeclined = "Normal quit declined"
    case keptDetails = "Kept open: details could not be safely dismissed"
    case keptCancelled = "Kept open: cleanup cancelled"
    case hideRequested = "Hide requested"
    case hideDeclined = "Hide declined"
    case keptExisting = "Kept open: existing visible instance"
    case keptUnverified = "Kept open: launch ownership unverified"
}

/// Fixed states only: never retain names, UI text, paths, timestamps, or process IDs.
struct FindMySessionReport: Equatable, Sendable {
    let outcome: FindMyRequestOutcome
    let launched: Bool
    let initiallyHidden: Bool
    let activated: Bool
    let cleanup: FindMyCleanupResult

    var text: String {
        """
        Last operation (memory only):
          Sound invocation attempted: \(outcome.invocationAttempted)
          Playback observed: \(outcome.playbackObserved)
          New process identified: \(launched)
          Initially hidden: \(initiallyHidden)
          Activated during operation: \(activated)
          Cleanup: \(cleanup.rawValue)
        """
    }
}

@MainActor protocol FindMyProcess: AnyObject {
    var isHidden: Bool { get }
    var isActive: Bool { get }
    var isTerminated: Bool { get }
    var launchDate: Date? { get }
    func unhide() -> Bool
    func hide() -> Bool
    func terminate() -> Bool
}

extension NSRunningApplication: FindMyProcess {}

@MainActor protocol FindMyWorkspace {
    associatedtype Process: FindMyProcess
    func runningFindMy() -> Process?
    func launchFindMy(configuration: NSWorkspace.OpenConfiguration) async throws -> Process
    func observeFindMyActivation(_ handler: @escaping @MainActor () -> Void) -> () -> Void
    func pause() async throws
    var now: Date { get }
}

/// Exists only for one explicit operation; no workspace observer remains while idle.
@MainActor final class FindMySession<Workspace: FindMyWorkspace> {
    private let workspace: Workspace
    private var process: Workspace.Process?
    private var launched = false
    private var originallyHidden = false
    private var becameActive = false
    private var foundExisting = false
    private var stopObserving: (() -> Void)?
    private var finishing = false

    private init(workspace: Workspace) { self.workspace = workspace }

    static func open(using workspace: Workspace) async throws -> FindMySession {
        try Task.checkCancellation()
        let session = FindMySession(workspace: workspace)
        session.stopObserving = workspace.observeFindMyActivation { [weak session] in
            session?.becameActive = true
        }
        do {
            let app: Workspace.Process
            if let running = workspace.runningFindMy() {
                app = running
                session.foundExisting = true
                session.originallyHidden = app.isHidden
            } else {
                let requestedAt = workspace.now
                let configuration = NSWorkspace.OpenConfiguration()
                configuration.activates = false
                // A deliberately hidden Find My ignores navigation on the inspected OS.
                configuration.hides = false
                configuration.addsToRecentItems = false
                app = try await workspace.launchFindMy(configuration: configuration)
                // openApplication may return an instance launched between our lookup
                // and the request. Unknown/older launch dates never authorize quitting.
                session.launched = app.launchDate.map { $0 >= requestedAt } ?? false
            }
            session.process = app
            try Task.checkCancellation()
            guard !app.isTerminated else { throw PingError.appUnavailable }
            if app.isHidden, !app.unhide() { throw PingError.appUnavailable }
            // Unhide is asynchronous. Give its run loop time before pressing a row.
            for _ in 0..<20 {
                try Task.checkCancellation()
                guard !app.isTerminated else { throw PingError.appUnavailable }
                if !app.isHidden { return session }
                try await workspace.pause()
            }
            throw PingError.appUnavailable
        } catch {
            await session.finish(.notSubmitted)
            throw error
        }
    }

    var application: Workspace.Process { process! } // Assigned before open returns.

    /// Rechecked immediately before the details Close action, without an intervening await.
    var mayDismissDetails: Bool {
        launched && stopObserving != nil && !Task.isCancelled &&
            !(process?.isTerminated ?? true) && !wasActivated
    }

    private var wasActivated: Bool { becameActive || (process?.isActive ?? false) }

    @discardableResult func finish(
        _ outcome: FindMyRequestOutcome,
        prepareToQuit: @MainActor () async -> Bool = { true }
    ) async -> FindMySessionReport? {
        guard let stopObserving, !finishing else { return nil }
        finishing = true
        defer {
            self.stopObserving = nil
            stopObserving()
        }
        func report(_ cleanup: FindMyCleanupResult) -> FindMySessionReport {
            FindMySessionReport(outcome: outcome, launched: launched, initiallyHidden: originallyHidden,
                                activated: wasActivated, cleanup: cleanup)
        }
        guard let app = process else { return report(.noProcess) }
        guard !app.isTerminated else { return report(.alreadyExited) }
        guard !wasActivated else { return report(.keptActive) }
        // An accepted AX action can precede delivery. Do not close a pending request.
        guard outcome != .submitted else { return report(.keptPending) }
        if launched {
            if outcome.playbackObserved {
                guard !Task.isCancelled else { return report(.keptCancelled) }
                let ready = await prepareToQuit()
                guard !wasActivated else { return report(.keptActive) }
                guard !app.isTerminated else { return report(.alreadyExited) }
                guard !Task.isCancelled else { return report(.keptCancelled) }
                guard ready else { return report(.keptDetails) }
            }
            guard app.terminate() else { return report(.quitDeclined) }
            // A successful terminate() only confirms delivery of the quit request.
            // Keep observing activation until this bounded exit check has finished.
            for _ in 0..<20 {
                if app.isTerminated { return report(.quitConfirmed) }
                if wasActivated || Task.isCancelled { break }
                do { try await workspace.pause() } catch { break }
            }
            return report(app.isTerminated ? .quitConfirmed : .quitUnconfirmed)
        }
        if originallyHidden && !app.isHidden { return report(app.hide() ? .hideRequested : .hideDeclined) }
        return report(foundExisting ? .keptExisting : .keptUnverified)
    }
}

@MainActor struct NativeFindMyWorkspace: FindMyWorkspace {
    var now: Date { Date() }
    func runningFindMy() -> NSRunningApplication? {
        NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.findmy").first
    }

    func launchFindMy(configuration: NSWorkspace.OpenConfiguration) async throws -> NSRunningApplication {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.findmy") else {
            throw PingError.appUnavailable
        }
        do { return try await NSWorkspace.shared.openApplication(at: url, configuration: configuration) }
        catch { throw PingError.appUnavailable }
    }

    func observeFindMyActivation(_ handler: @escaping @MainActor () -> Void) -> () -> Void {
        let center = NSWorkspace.shared.notificationCenter
        let token = center.addObserver(forName: NSWorkspace.didActivateApplicationNotification,
                                       object: nil, queue: .main) { notification in
            guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
                  app.bundleIdentifier == "com.apple.findmy" else { return }
            MainActor.assumeIsolated { handler() }
        }
        return { center.removeObserver(token) }
    }

    func pause() async throws { try await Task.sleep(nanoseconds: 100_000_000) }
}
