import AppKit
import XCTest
import PhonePingCore
@testable import PhonePing

@MainActor private final class TestProcess: FindMyProcess {
    var isHidden = false
    var isActive = false
    var isTerminated = false
    var launchDate: Date? = Date(timeIntervalSince1970: 10)
    var unhideSucceeds = true
    var unhideIsDelayed = false
    var hideSucceeds = true
    var terminateSucceeds = true
    var terminateIsDelayed = false
    var calls: [String] = []
    func unhide() -> Bool {
        calls.append("unhide")
        if unhideSucceeds && !unhideIsDelayed { isHidden = false }
        return unhideSucceeds
    }
    func hide() -> Bool { calls.append("hide"); if hideSucceeds { isHidden = true }; return hideSucceeds }
    func terminate() -> Bool { calls.append("terminate"); if terminateSucceeds && !terminateIsDelayed { isTerminated = true }; return terminateSucceeds }
}

@MainActor private final class TestWorkspace: FindMyWorkspace {
    var process = TestProcess()
    var alreadyRunning = true
    var launchFails = false
    var configurations: [(activates: Bool, hides: Bool, recents: Bool)] = []
    var observer: (@MainActor () -> Void)?
    var observersRemoved = 0
    var pauses = 0
    var onPause: (() throws -> Void)?
    var now = Date(timeIntervalSince1970: 10)

    func runningFindMy() -> TestProcess? { alreadyRunning ? process : nil }
    func launchFindMy(configuration: NSWorkspace.OpenConfiguration) async throws -> TestProcess {
        configurations.append((configuration.activates, configuration.hides, configuration.addsToRecentItems))
        if launchFails { throw PingError.appUnavailable }
        return process
    }
    func observeFindMyActivation(_ handler: @escaping @MainActor () -> Void) -> () -> Void {
        observer = handler
        return { self.observer = nil; self.observersRemoved += 1 }
    }
    func pause() async throws { pauses += 1; try onPause?() }
}

@MainActor final class FindMySessionTests: XCTestCase {
    func testExistingPlaybackCanCleanUpOnlyAfterDetailsVerification() async throws {
        for allowed in [false, true] {
            let workspace = TestWorkspace()
            workspace.alreadyRunning = false
            let session = try await FindMySession.open(using: workspace)
            var checked = false
            let report = await session.finish(.alreadyPlaying) {
                checked = true
                return allowed
            }
            XCTAssertTrue(checked)
            XCTAssertEqual(report?.cleanup, allowed ? .quitConfirmed : .keptDetails)
            XCTAssertEqual(workspace.process.calls, allowed ? ["terminate"] : [])
            XCTAssertTrue(report?.text.contains("Sound invocation attempted: false") == true)
            XCTAssertTrue(report?.text.contains("Playback observed: true") == true)
            XCTAssertNil(workspace.observer)
        }
    }

    func testExistingPlaybackPreservesAnExistingOrActivatedSession() async throws {
        for existing in [false, true] {
            let workspace = TestWorkspace()
            workspace.alreadyRunning = existing
            let session = try await FindMySession.open(using: workspace)
            if !existing { workspace.observer?() }
            let report = await session.finish(.alreadyPlaying) {
                XCTFail("Must not prepare this session for quitting")
                return true
            }
            XCTAssertEqual(report?.cleanup, existing ? .keptExisting : .keptActive)
            XCTAssertTrue(workspace.process.calls.isEmpty)
            XCTAssertNil(workspace.observer)
        }
    }

    func testAcceptedQuitThatDoesNotExitIsBoundedAndNotReportedAsClosed() async throws {
        let workspace = TestWorkspace()
        workspace.alreadyRunning = false
        workspace.process.terminateIsDelayed = true
        let session = try await FindMySession.open(using: workspace)
        let report = await session.finish(.playing)
        XCTAssertEqual(report?.cleanup, .quitUnconfirmed)
        XCTAssertEqual(workspace.pauses, 20)
        XCTAssertEqual(workspace.process.calls, ["terminate"])
        XCTAssertNil(workspace.observer)
    }

    func testWaitsForDelayedQuitAndRemovesObserverAfterExit() async throws {
        let workspace = TestWorkspace()
        workspace.alreadyRunning = false
        workspace.process.terminateIsDelayed = true
        workspace.onPause = {
            XCTAssertNotNil(workspace.observer)
            workspace.process.isTerminated = true
        }
        let session = try await FindMySession.open(using: workspace)
        let report = await session.finish(.playing)
        XCTAssertEqual(report?.cleanup, .quitConfirmed)
        XCTAssertEqual(workspace.pauses, 1)
        XCTAssertNil(workspace.observer)
    }

    func testDetailsMustBeDismissedBeforeNormalQuit() async throws {
        let workspace = TestWorkspace()
        workspace.alreadyRunning = false
        let session = try await FindMySession.open(using: workspace)
        let report = await session.finish(.playing) {
            XCTAssertTrue(session.mayDismissDetails)
            XCTAssertTrue(workspace.process.calls.isEmpty)
            return false
        }
        XCTAssertEqual(report?.cleanup, .keptDetails)
        XCTAssertTrue(workspace.process.calls.isEmpty)
        XCTAssertNil(workspace.observer)
    }

    func testActivationDuringDismissalCancelsQuitEvenAfterSwitchingAway() async throws {
        let workspace = TestWorkspace()
        workspace.alreadyRunning = false
        let session = try await FindMySession.open(using: workspace)
        let report = await session.finish(.playing) {
            workspace.observer?()
            workspace.process.isActive = false
            XCTAssertFalse(session.mayDismissDetails)
            return true
        }
        XCTAssertEqual(report?.cleanup, .keptActive)
        XCTAssertEqual(report?.activated, true)
        XCTAssertTrue(workspace.process.calls.isEmpty)
        XCTAssertNil(workspace.observer)
    }

    func testExistingAndPendingSessionsNeverPrepareToQuit() async throws {
        for (existing, outcome) in [(true, FindMyRequestOutcome.playing), (false, .submitted)] {
            let workspace = TestWorkspace()
            workspace.alreadyRunning = existing
            let session = try await FindMySession.open(using: workspace)
            _ = await session.finish(outcome) {
                XCTFail("Must not dismiss this session’s details")
                return true
            }
            XCTAssertTrue(workspace.process.calls.isEmpty)
            XCTAssertNil(workspace.observer)
        }
    }

    func testActivationDuringExitWaitStopsWaitingWithoutFurtherActions() async throws {
        let workspace = TestWorkspace()
        workspace.alreadyRunning = false
        workspace.process.terminateIsDelayed = true
        workspace.onPause = { workspace.observer?() }
        let session = try await FindMySession.open(using: workspace)
        let report = await session.finish(.playing)
        XCTAssertEqual(report?.cleanup, .quitUnconfirmed)
        XCTAssertEqual(report?.activated, true)
        XCTAssertEqual(workspace.pauses, 1)
        XCTAssertEqual(workspace.process.calls, ["terminate"])
        XCTAssertNil(workspace.observer)
    }

    func testReentrantCleanupCannotSendAnotherQuit() async throws {
        let workspace = TestWorkspace()
        workspace.alreadyRunning = false
        let session = try await FindMySession.open(using: workspace)
        _ = await session.finish(.playing) {
            let nested = await session.finish(.playing)
            XCTAssertNil(nested)
            return true
        }
        XCTAssertEqual(workspace.process.calls, ["terminate"])
        XCTAssertEqual(workspace.observersRemoved, 1)
    }

    func testCancellationDuringDismissalPreventsQuitAndRemovesObserver() async throws {
        let workspace = TestWorkspace()
        workspace.alreadyRunning = false
        let session = try await FindMySession.open(using: workspace)
        let task = Task {
            await session.finish(.playing) {
                withUnsafeCurrentTask { $0?.cancel() }
                return true
            }
        }
        let report = await task.value
        XCTAssertEqual(report?.cleanup, .keptCancelled)
        XCTAssertTrue(workspace.process.calls.isEmpty)
        XCTAssertNil(workspace.observer)
    }

    func testColdLaunchDoesNotRequestActivationOrHideItsControls() async throws {
        let workspace = TestWorkspace()
        workspace.alreadyRunning = false
        let session = try await FindMySession.open(using: workspace)
        XCTAssertEqual(workspace.configurations.count, 1)
        XCTAssertFalse(workspace.configurations[0].activates)
        XCTAssertFalse(workspace.configurations[0].hides)
        XCTAssertFalse(workspace.configurations[0].recents)
        let report = await session.finish(.playing)
        XCTAssertEqual(report?.cleanup, .quitConfirmed)
        XCTAssertEqual(report?.launched, true)
        XCTAssertEqual(workspace.process.calls, ["terminate"])
        XCTAssertNil(workspace.observer)
    }

    func testAnExistingVisibleAppIsNeverHiddenOrQuit() async throws {
        let workspace = TestWorkspace()
        let session = try await FindMySession.open(using: workspace)
        await session.finish(.playing)
        XCTAssertTrue(workspace.process.calls.isEmpty)
        XCTAssertTrue(workspace.configurations.isEmpty)
        XCTAssertEqual(workspace.observersRemoved, 1)
    }

    func testOpenReturningAnOlderProcessDoesNotTakeOwnership() async throws {
        let workspace = TestWorkspace()
        workspace.alreadyRunning = false
        workspace.process.launchDate = workspace.now.addingTimeInterval(-1)
        let session = try await FindMySession.open(using: workspace)
        await session.finish(.playing)
        XCTAssertTrue(workspace.process.calls.isEmpty)
    }

    func testUnknownLaunchDateDoesNotAuthorizeQuitting() async throws {
        let workspace = TestWorkspace()
        workspace.alreadyRunning = false
        workspace.process.launchDate = nil
        let session = try await FindMySession.open(using: workspace)
        let cleanupReport1 = await session.finish(.playing)
        XCTAssertEqual(cleanupReport1?.cleanup, .keptUnverified)
        XCTAssertTrue(workspace.process.calls.isEmpty)
    }

    func testAnExistingHiddenAppReturnsToHiddenAfterPlayback() async throws {
        let workspace = TestWorkspace()
        workspace.process.isHidden = true
        let session = try await FindMySession.open(using: workspace)
        await session.finish(.playing)
        XCTAssertEqual(workspace.process.calls, ["unhide", "hide"])
        XCTAssertFalse(workspace.process.isTerminated)
    }

    func testPendingColdLaunchIsNotQuit() async throws {
        let workspace = TestWorkspace()
        workspace.alreadyRunning = false
        let session = try await FindMySession.open(using: workspace)
        let cleanupReport2 = await session.finish(.submitted)
        XCTAssertEqual(cleanupReport2?.cleanup, .keptPending)
        XCTAssertTrue(workspace.process.calls.isEmpty)
        XCTAssertNil(workspace.observer)
    }

    func testPendingRequestIsNotHidden() async throws {
        let workspace = TestWorkspace()
        workspace.process.isHidden = true
        let session = try await FindMySession.open(using: workspace)
        await session.finish(.submitted)
        XCTAssertEqual(workspace.process.calls, ["unhide"])
    }

    func testUserActivationPreventsCleanupEvenAfterSwitchingAway() async throws {
        let workspace = TestWorkspace()
        workspace.alreadyRunning = false
        let session = try await FindMySession.open(using: workspace)
        workspace.observer?()
        workspace.process.isActive = false
        let report = await session.finish(.playing)
        XCTAssertEqual(report?.cleanup, .keptActive)
        XCTAssertEqual(report?.activated, true)
        XCTAssertTrue(workspace.process.calls.isEmpty)
        XCTAssertNil(workspace.observer)
    }

    func testActiveAppIsNeverQuitEvenIfNotificationHasNotArrived() async throws {
        let workspace = TestWorkspace()
        workspace.alreadyRunning = false
        let session = try await FindMySession.open(using: workspace)
        workspace.process.isActive = true
        await session.finish(.playing)
        XCTAssertTrue(workspace.process.calls.isEmpty)
    }

    func testUnhideWaitsForTheProcessBeforeReturning() async throws {
        let workspace = TestWorkspace()
        workspace.process.isHidden = true
        workspace.process.unhideIsDelayed = true
        workspace.onPause = { workspace.process.isHidden = false }
        let session = try await FindMySession.open(using: workspace)
        XCTAssertEqual(workspace.pauses, 1)
        XCTAssertFalse(session.application.isHidden)
        await session.finish(.notSubmitted)
        XCTAssertEqual(workspace.process.calls, ["unhide", "hide"])
    }

    func testUnhideTimeoutStopsAndRemovesObserver() async {
        let workspace = TestWorkspace()
        workspace.process.isHidden = true
        workspace.process.unhideIsDelayed = true
        do {
            _ = try await FindMySession.open(using: workspace)
            XCTFail("Expected bounded unhide failure")
        } catch { XCTAssertEqual(error as? PingError, .appUnavailable) }
        XCTAssertEqual(workspace.pauses, 20)
        XCTAssertEqual(workspace.process.calls, ["unhide"])
        XCTAssertNil(workspace.observer)
    }

    // unhide() can return false while the app still becomes visible on a later run-loop turn.
    func testFalseUnhideReturnProceedsWhenTheAppBecomesVisible() async throws {
        let workspace = TestWorkspace()
        workspace.process.isHidden = true
        workspace.process.unhideSucceeds = false
        workspace.onPause = { workspace.process.isHidden = false }
        let session = try await FindMySession.open(using: workspace)
        XCTAssertFalse(session.application.isHidden)
        XCTAssertEqual(workspace.process.calls, ["unhide"])
        await session.finish(.playing)
        XCTAssertEqual(workspace.process.calls, ["unhide", "hide"])
    }

    func testFalseUnhideReturnStillStopsIfTheAppStaysHidden() async {
        let workspace = TestWorkspace()
        workspace.process.isHidden = true
        workspace.process.unhideSucceeds = false
        do {
            _ = try await FindMySession.open(using: workspace)
            XCTFail("Expected bounded unhide failure")
        } catch { XCTAssertEqual(error as? PingError, .appUnavailable) }
        XCTAssertEqual(workspace.pauses, 20)
        XCTAssertEqual(workspace.process.calls, ["unhide"])
        XCTAssertNil(workspace.observer)
    }

    func testVisibilityIsCheckedAfterTheLastWait() async throws {
        let workspace = TestWorkspace()
        workspace.process.isHidden = true
        workspace.process.unhideIsDelayed = true
        workspace.onPause = { if workspace.pauses == 20 { workspace.process.isHidden = false } }
        let session = try await FindMySession.open(using: workspace)
        XCTAssertFalse(session.application.isHidden)
        XCTAssertEqual(workspace.pauses, 20)
        XCTAssertEqual(workspace.process.calls, ["unhide"])
        await session.finish(.notSubmitted)
    }

    func testFailedLaunchRemovesObserver() async {
        let workspace = TestWorkspace()
        workspace.alreadyRunning = false
        workspace.launchFails = true
        do {
            _ = try await FindMySession.open(using: workspace)
            XCTFail("Expected launch failure")
        } catch { XCTAssertEqual(error as? PingError, .appUnavailable) }
        XCTAssertNil(workspace.observer)
        XCTAssertTrue(workspace.process.calls.isEmpty)
    }

    func testCancellationBeforeSubmissionCleansUpNewProcess() async {
        let workspace = TestWorkspace()
        workspace.alreadyRunning = false
        workspace.process.isHidden = true
        workspace.process.unhideIsDelayed = true
        workspace.onPause = { throw CancellationError() }
        do {
            _ = try await FindMySession.open(using: workspace)
            XCTFail("Expected cancellation")
        } catch { XCTAssertTrue(error is CancellationError) }
        XCTAssertEqual(workspace.process.calls, ["unhide", "terminate"])
        XCTAssertNil(workspace.observer)
    }

    func testCleanupIsIdempotentAndHandlesAnAlreadyClosedProcess() async throws {
        let workspace = TestWorkspace()
        workspace.alreadyRunning = false
        let session = try await FindMySession.open(using: workspace)
        workspace.process.isTerminated = true
        let cleanupReport3 = await session.finish(.playing)
        XCTAssertEqual(cleanupReport3?.cleanup, .alreadyExited)
        let cleanupReport4 = await session.finish(.playing)
        XCTAssertNil(cleanupReport4)
        XCTAssertTrue(workspace.process.calls.isEmpty)
        XCTAssertEqual(workspace.observersRemoved, 1)
    }

    func testDeclinedQuitIsReportedWithoutRetryOrForceQuit() async throws {
        let workspace = TestWorkspace()
        workspace.alreadyRunning = false
        workspace.process.terminateSucceeds = false
        let session = try await FindMySession.open(using: workspace)
        let cleanupReport5 = await session.finish(.playing)
        XCTAssertEqual(cleanupReport5?.cleanup, .quitDeclined)
        XCTAssertEqual(workspace.process.calls, ["terminate"])
        XCTAssertFalse(workspace.process.isTerminated)
        let cleanupReport6 = await session.finish(.playing)
        XCTAssertNil(cleanupReport6)
        XCTAssertEqual(workspace.process.calls, ["terminate"])
    }

    func testDeclinedHideIsReportedWithoutTryingToQuitExistingApp() async throws {
        let workspace = TestWorkspace()
        workspace.process.isHidden = true
        workspace.process.hideSucceeds = false
        let session = try await FindMySession.open(using: workspace)
        let cleanupReport7 = await session.finish(.playing)
        XCTAssertEqual(cleanupReport7?.cleanup, .hideDeclined)
        XCTAssertEqual(workspace.process.calls, ["unhide", "hide"])
        XCTAssertFalse(workspace.process.isHidden)
        XCTAssertFalse(workspace.process.isTerminated)
    }
}
