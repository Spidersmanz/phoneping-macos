import XCTest
import PhonePingCore
@testable import PhonePing

/// Each fixture is owned by one test and used by one automation actor. No live AX access.
private final class SyntheticAccess: FindMyAccess, @unchecked Sendable {
    struct Node {
        var text: [String: String] = [:]
        var numbers: [String: Int] = [:]
        var children: [Int] = []
        var frame: CGRect? = nil
        var actions: [String] = []
        var focusedWindow: Int? = nil
    }
    var tree: [Int: Node] = [:]
    var now = ContinuousClock.now
    var invocations: [(Int, String)] = []
    var permission = true
    var transientReads = 0
    var missingLabel = false
    var submitFails = false
    var detailsName = "Test Phone"
    var soundLabel = "Play Sound,Off"
    var soundEnabled = 1
    var additionalSoundLabel: String?
    var extraSheet = false
    var introduceDuplicate = false
    var pauseCancels = false
    var timeoutOnOpen = false
    var focusedSheetOnly = false
    var headerInValue = false
    var conflictingHeaderValue = false
    var running = true
    var launches = 0
    var advanceClockOnRead = false
    var hidesListInDetails = false
    var partialListInDetails = false
    var emptyListContainerInDetails = false
    var missingTabReads = 0
    var outcomes: [FindMyRequestOutcome] = []
    var reportsPlaying = true
    var changesNameAfterSubmission = false
    var changesLabelAfterSubmission: String?
    var removesDetailsAfterSubmission = false
    var lastOperation: FindMySessionReport?
    var cleanupSelections: [String?] = []
    var keepsDetailsAfterClose = false
    var closeFails = false
    var onClose: (() -> Void)?

    init() {
        tree[0] = Node(text: ["AXRole": "AXApplication"], children: [1])
        tree[1] = Node(text: ["AXRole": "AXWindow"], children: [2], frame: CGRect(x: 0, y: 0, width: 900, height: 700))
        tree[2] = Node(text: ["AXIdentifier": "CardContainerView", "AXRole": "AXGroup"], children: [3,4], frame: CGRect(x: 0, y: 50, width: 320, height: 600))
        tree[3] = Node(text: ["AXRole": "AXRadioButton", "AXDescription": "Devices"], numbers: ["AXValue": 1], actions: ["AXPress"])
        tree[4] = Node(text: ["AXRole": "AXGroup"], children: [5,6])
        tree[5] = row("Test Phone", y: 140)
        tree[6] = row("Test Watch", y: 230)
    }
    func row(_ name: String, y: Double) -> Node {
        Node(text: ["AXRole": "AXStaticText", "AXIdentifier": "ListEntityRow", "AXDescription": name + ", Synthetic status"], frame: CGRect(x: 20, y: y, width: 280, height: 75), actions: ["AXPress", "Open Details", "Erase Device"])
    }
    func application() async throws -> Int {
        launches += 1
        if !permission { throw PingError.permission }
        return 0
    }
    func finish(_ outcome: FindMyRequestOutcome, selection: String?) async { outcomes.append(outcome); cleanupSelections.append(selection) }
    func operationReport() async -> FindMySessionReport? { lastOperation }
    func runningApplication() async throws -> Int? {
        if !permission { throw PingError.permission }
        return running ? 0 : nil
    }
    func diagnosticValue(_ element: Int, _ attribute: String) throws -> DiagnosticValue {
        if let number = tree[element]?.numbers[attribute] { return .classify(NSNumber(value: number)) }
        return .classify(tree[element]?.text[attribute] as NSString?)
    }
    func text(_ element: Int, _ attribute: String) throws -> String? {
        if advanceClockOnRead { now = now.advanced(by: .seconds(6)) }
        if element == 3 && attribute == "AXDescription" && missingTabReads > 0 {
            missingTabReads -= 1
            return nil
        }
        if element == 6 && attribute == "AXDescription" {
            if transientReads > 0 { transientReads -= 1; throw DiscoveryFailure.temporarilyUnavailable }
            if missingLabel { return nil }
        }
        return tree[element]?.text[attribute]
    }
    func number(_ element: Int, _ attribute: String) throws -> Int? { tree[element]?.numbers[attribute] }
    func elements(_ element: Int, _ attribute: String) throws -> [Int]? {
        return attribute == "AXChildren" ? tree[element]?.children : nil
    }
    func element(_ element: Int, _ attribute: String) throws -> Int? { attribute == "AXFocusedWindow" ? tree[element]?.focusedWindow : nil }
    func frame(_ element: Int) throws -> CGRect? { tree[element]?.frame }
    func actions(_ element: Int) throws -> [String] { tree[element]?.actions ?? [] }
    func actionDescription(_ action: String, on element: Int) throws -> String? { action }
    func pause() async throws {
        if pauseCancels { throw CancellationError() }
        now = now.advanced(by: .milliseconds(250))
    }
    func perform(_ action: String, on element: Int) throws {
        invocations.append((element, action))
        switch element {
        case 3: tree[3]?.numbers["AXValue"] = 1
        case 5:
            if timeoutOnOpen { now = now.advanced(by: .seconds(11)) }
            if focusedSheetOnly { tree[0]?.focusedWindow = 10 }
            else if hidesListInDetails { tree[1]?.children = [10] }
            else { tree[1]?.children.append(10) }
            if partialListInDetails { tree[2]?.children.removeAll { $0 == 3 } }
            if emptyListContainerInDetails {
                tree[1]?.children = [2,10]
                tree[2]?.children = []
            }
            tree[10] = Node(text: ["AXRole": "AXSheet"], children: [11,13,14])
            tree[11] = Node(text: ["AXIdentifier": "PrimaryLabel"], children: [12])
            tree[12] = Node(text: ["AXRole": "AXStaticText", headerInValue ? "AXValue" : "AXDescription": detailsName])
            if conflictingHeaderValue { tree[12]?.text["AXValue"] = "Other Test Phone" }
            tree[13] = Node(text: ["AXIdentifier": "FMPlatterButton", "AXRole": "AXButton", "AXDescription": soundLabel], numbers: ["AXEnabled": soundEnabled])
            if let label = additionalSoundLabel {
                tree[10]?.children.append(16)
                tree[16] = Node(text: ["AXIdentifier": "FMPlatterButton", "AXRole": "AXButton", "AXDescription": label], numbers: ["AXEnabled": 1])
            }
            tree[14] = Node(text: ["AXIdentifier": "Close", "AXRole": "AXButton"], numbers: ["AXEnabled": 1], actions: ["AXPress"])
            if extraSheet {
                tree[1]?.children.append(15)
                tree[15] = Node(text: ["AXRole": "AXSheet"])
            }
            if introduceDuplicate { tree[6] = row("Test Phone", y: 230) }
        case 13:
            if submitFails { throw DiscoveryFailure.temporarilyUnavailable }
            if reportsPlaying { tree[13]?.text["AXDescription"] = "Play Sound,Playing…" }
            if let label = changesLabelAfterSubmission { tree[13]?.text["AXDescription"] = label }
            if changesNameAfterSubmission { tree[12]?.text["AXDescription"] = "Another Test Phone" }
            if removesDetailsAfterSubmission { tree[1]?.children = [2]; tree[0]?.focusedWindow = nil }
        case 14:
            if closeFails { throw DiscoveryFailure.temporarilyUnavailable }
            onClose?()
            if keepsDetailsAfterClose { return }
            tree[1]?.children.removeAll { $0 == 10 }
            if hidesListInDetails { tree[1]?.children = [2] }
            tree[0]?.focusedWindow = nil
        default: break
        }
    }
    var submissions: Int { invocations.filter { $0.0 == 13 }.count }
}

final class FindMyAutomationTests: XCTestCase {
    private func expect(_ expected: PingError, fixture: SyntheticAccess, file: StaticString = #filePath, line: UInt = #line) async {
        do {
            try await FindMyAutomation(access: fixture).play(on: "Test Phone")
            XCTFail("Expected a guarded failure", file: file, line: line)
        } catch { XCTAssertEqual(error as? PingError, expected, file: file, line: line) }
    }

    func testObservedExistingPlaybackDoesNotSubmitAnotherSound() async throws {
        let fixture = SyntheticAccess()
        fixture.soundLabel = "Play Sound,Playing…"
        let result = try await FindMyAutomation(access: fixture).play(on: "Test Phone")
        XCTAssertEqual(result, .alreadyPlaying)
        XCTAssertEqual(fixture.outcomes, [.alreadyPlaying])
        XCTAssertEqual(fixture.cleanupSelections, ["Test Phone"])
        XCTAssertEqual(fixture.submissions, 0)
    }

    func testPreparationAttemptsAnIgnoredCloseOnlyOnce() async throws {
        let fixture = SyntheticAccess()
        try fixture.perform("Open Details", on: 5)
        fixture.invocations = []
        fixture.keepsDetailsAfterClose = true
        await expect(.unsupportedInterface, fixture: fixture)
        XCTAssertEqual(fixture.invocations.filter { $0.0 == 14 }.count, 1)
        XCTAssertEqual(fixture.submissions, 0)
    }

    func testPreparationDoesNotRetryAFailedClose() async throws {
        let fixture = SyntheticAccess()
        try fixture.perform("Open Details", on: 5)
        fixture.invocations = []
        fixture.closeFails = true
        await expect(.unsupportedInterface, fixture: fixture)
        XCTAssertEqual(fixture.invocations.filter { $0.0 == 14 }.count, 1)
        XCTAssertEqual(fixture.submissions, 0)
    }

    func testPreparationLeavesDisabledCloseAlone() async throws {
        let fixture = SyntheticAccess()
        try fixture.perform("Open Details", on: 5)
        fixture.invocations = []
        fixture.tree[14]?.numbers["AXEnabled"] = 0
        await expect(.unsupportedInterface, fixture: fixture)
        XCTAssertTrue(fixture.invocations.isEmpty)
    }

    func testExistingPlaybackStillRequiresTheSelectedDetailsName() async {
        let fixture = SyntheticAccess()
        fixture.soundLabel = "Play Sound,Playing…"
        fixture.detailsName = "Another Test Phone"
        await expect(.detailsChanged, fixture: fixture)
        XCTAssertEqual(fixture.outcomes, [.notSubmitted])
        XCTAssertEqual(fixture.submissions, 0)
    }

    func testConflictingSoundControlsDoNotClaimOrSubmitPlayback() async {
        for label in ["Play Sound,Off", "Play Sound,Playing…"] {
            let fixture = SyntheticAccess()
            fixture.soundLabel = "Play Sound,Playing…"
            fixture.additionalSoundLabel = label
            await expect(.unsupportedInterface, fixture: fixture)
            XCTAssertEqual(fixture.outcomes, [.notSubmitted])
            XCTAssertEqual(fixture.submissions, 0)
        }
    }

    func testPreparationRequiresRecognizedDetailsAndAnAvailableCloseAction() async throws {
        for missing in ["header", "name", "sound", "close action"] {
            let fixture = SyntheticAccess()
            try fixture.perform("Open Details", on: 5)
            fixture.invocations = []
            switch missing {
            case "header": fixture.tree[11]?.text = [:]
            case "name": fixture.tree[12]?.text["AXDescription"] = "  "
            case "sound": fixture.tree[13]?.text["AXDescription"] = "Erase Device"
            default: fixture.tree[14]?.actions = []
            }
            await expect(.unsupportedInterface, fixture: fixture)
            XCTAssertTrue(fixture.invocations.isEmpty, missing)
        }
    }

    func testPreparationNeverDismissesAnUnexpectedDialog() async throws {
        for role in ["AXAlert", "AXDialog", "AXWindow"] {
            let fixture = SyntheticAccess()
            try fixture.perform("Open Details", on: 5)
            fixture.invocations = []
            fixture.tree[10]?.children.append(17)
            fixture.tree[17] = .init(text: ["AXRole": role, "AXSubrole": "AXSystemDialog"])
            await expect(.unsupportedInterface, fixture: fixture)
            XCTAssertTrue(fixture.invocations.isEmpty, role)
        }
    }

    func testPreparationClosesRecognizedPriorDetailsBeforeSelectingTarget() async throws {
        let fixture = SyntheticAccess()
        fixture.detailsName = "Test Watch"
        try fixture.perform("Open Details", on: 5)
        fixture.invocations = []
        fixture.detailsName = "Test Phone"
        let result = try await FindMyAutomation(access: fixture).play(on: "Test Phone")
        XCTAssertEqual(result, .submitted)
        XCTAssertEqual(fixture.invocations.map { $0.0 }, [14, 5, 13])
        XCTAssertEqual(fixture.outcomes, [.playing])
    }

    func testPlayingStatusAllowsCleanupAfterExactlyOneSubmission() async throws {
        let fixture = SyntheticAccess()
        try await FindMyAutomation(access: fixture).play(on: "Test Phone")
        XCTAssertEqual(fixture.outcomes, [.playing])
        XCTAssertEqual(fixture.cleanupSelections, ["Test Phone"])
        XCTAssertEqual(fixture.submissions, 1)
    }
    func testPendingPlaybackKeepsApplicationAvailableWithoutResubmitting() async throws {
        let fixture = SyntheticAccess()
        fixture.reportsPlaying = false
        try await FindMyAutomation(access: fixture).play(on: "Test Phone")
        XCTAssertEqual(fixture.outcomes, [.submitted])
        XCTAssertEqual(fixture.submissions, 1)
    }
    func testUncertainSubmissionDoesNotPermitCleanup() async {
        let fixture = SyntheticAccess()
        fixture.submitFails = true
        await expect(.requestUncertain, fixture: fixture)
        XCTAssertEqual(fixture.outcomes, [.submitted])
        XCTAssertEqual(fixture.submissions, 1)
    }
    func testPostSubmissionNameChangeDoesNotClaimPlayback() async throws {
        let fixture = SyntheticAccess()
        fixture.changesNameAfterSubmission = true
        try await FindMyAutomation(access: fixture).play(on: "Test Phone")
        XCTAssertEqual(fixture.outcomes, [.submitted])
        XCTAssertEqual(fixture.submissions, 1)
    }
    func testUnrecognizedPlaybackTextDoesNotPermitCleanup() async throws {
        let fixture = SyntheticAccess()
        fixture.changesLabelAfterSubmission = "Play Sound,Not Playing…"
        try await FindMyAutomation(access: fixture).play(on: "Test Phone")
        XCTAssertEqual(fixture.outcomes, [.submitted])
        XCTAssertEqual(fixture.submissions, 1)
    }
    func testMissingPostSubmissionSheetDoesNotPermitCleanup() async throws {
        let fixture = SyntheticAccess()
        fixture.removesDetailsAfterSubmission = true
        try await FindMyAutomation(access: fixture).play(on: "Test Phone")
        XCTAssertEqual(fixture.outcomes, [.submitted])
        XCTAssertEqual(fixture.submissions, 1)
    }
    func testFailureBeforeSubmissionCleansUpItsSession() async {
        let fixture = SyntheticAccess()
        fixture.detailsName = "Another Test Phone"
        await expect(.detailsChanged, fixture: fixture)
        XCTAssertEqual(fixture.outcomes, [.notSubmitted])
        XCTAssertEqual(fixture.submissions, 0)
    }
    func testRefreshCleansUpWithoutClaimingSound() async throws {
        let fixture = SyntheticAccess()
        _ = try await FindMyAutomation(access: fixture).devices()
        XCTAssertEqual(fixture.outcomes, [.notSubmitted])
        XCTAssertTrue(fixture.invocations.isEmpty)
    }
    func testReadOnlyDiagnosticDoesNotCreateOrCleanUpASession() async throws {
        let fixture = SyntheticAccess()
        _ = try await FindMyAutomation(access: fixture).diagnose(selection: "Test Phone")
        XCTAssertEqual(fixture.launches, 0)
        XCTAssertTrue(fixture.outcomes.isEmpty)
    }

    func testSuccessfulNavigationSubmitsOnceAndNeverUsesOtherActions() async throws {
        let fixture = SyntheticAccess()
        try await FindMyAutomation(access: fixture).play(on: "Test Phone")
        XCTAssertEqual(fixture.submissions, 1)
        XCTAssertEqual(fixture.invocations.map { $0.1 }, ["Open Details", "AXPress"])
    }
    func testModalDetailsCanReplaceTheEntireExposedDeviceList() async throws {
        let fixture = SyntheticAccess()
        fixture.hidesListInDetails = true
        try await FindMyAutomation(access: fixture).play(on: "Test Phone")
        XCTAssertEqual(fixture.submissions, 1)
        XCTAssertEqual(fixture.invocations.map { $0.1 }, ["Open Details", "AXPress"])
    }
    func testHiddenListStillRequiresExactDetailsName() async {
        let fixture = SyntheticAccess()
        fixture.hidesListInDetails = true
        fixture.detailsName = "Another Test Phone"
        await expect(.detailsChanged, fixture: fixture)
        XCTAssertEqual(fixture.submissions, 0)
    }
    func testHiddenListDoesNotBypassDisabledSoundGuard() async {
        let fixture = SyntheticAccess()
        fixture.hidesListInDetails = true
        fixture.soundEnabled = 0
        await expect(.unavailableAction, fixture: fixture)
        XCTAssertEqual(fixture.submissions, 0)
        XCTAssertEqual(fixture.invocations.map { $0.1 }, ["Open Details"])
    }
    func testPartialListIsNotTreatedAsAHiddenModalList() async {
        let fixture = SyntheticAccess()
        fixture.partialListInDetails = true
        await expect(.unavailableAction, fixture: fixture)
        XCTAssertEqual(fixture.submissions, 0)
    }
    func testEmptyContainerDoesNotRequireHiddenListToReappear() async throws {
        let fixture = SyntheticAccess()
        fixture.emptyListContainerInDetails = true
        try await FindMyAutomation(access: fixture).play(on: "Test Phone")
        XCTAssertEqual(fixture.submissions, 1)
    }
    func testFindsFocusedSheetOutsideWindowArray() async throws {
        let fixture = SyntheticAccess()
        fixture.focusedSheetOnly = true
        try await FindMyAutomation(access: fixture).play(on: "Test Phone")
        XCTAssertEqual(fixture.submissions, 1)
    }
    func testReadsStaticTextValueAsFullDeviceName() async throws {
        let fixture = SyntheticAccess()
        fixture.headerInValue = true
        try await FindMyAutomation(access: fixture).play(on: "Test Phone")
        XCTAssertEqual(fixture.submissions, 1)
    }
    func testConflictingHeaderDescriptionAndValueCannotRing() async {
        let fixture = SyntheticAccess()
        fixture.conflictingHeaderValue = true
        await expect(.detailsChanged, fixture: fixture)
        XCTAssertEqual(fixture.submissions, 0)
    }
    func testDuplicateNameStopsBeforeOpeningDetails() async {
        let fixture = SyntheticAccess()
        fixture.tree[6] = fixture.row("Test Phone", y: 230)
        await expect(.ambiguous, fixture: fixture)
        XCTAssertTrue(fixture.invocations.isEmpty)
    }
    func testOffscreenRowRejectsPartialList() async {
        let fixture = SyntheticAccess()
        fixture.tree[6] = fixture.row("Test Phone", y: 900)
        await expect(.incompleteList, fixture: fixture)
        XCTAssertTrue(fixture.invocations.isEmpty)
    }
    func testScrollingContainerRejectsUnexposedRows() async {
        let fixture = SyntheticAccess()
        fixture.tree[4]?.text["AXRole"] = "AXScrollArea"
        await expect(.incompleteList, fixture: fixture)
        XCTAssertTrue(fixture.invocations.isEmpty)
    }
    func testUnreadableLabelIsNotDroppedFromUniquenessCheck() async {
        let fixture = SyntheticAccess()
        fixture.missingLabel = true
        await expect(.incompleteList, fixture: fixture)
        XCTAssertEqual(fixture.submissions, 0)
    }
    func testTransientLabelReadRecoversWithFreshTree() async throws {
        let fixture = SyntheticAccess()
        fixture.transientReads = 2
        try await FindMyAutomation(access: fixture).play(on: "Test Phone")
        XCTAssertEqual(fixture.submissions, 1)
    }
    func testWrongFullDetailsHeaderCannotRing() async {
        let fixture = SyntheticAccess()
        fixture.detailsName = "Test Phone, Work"
        await expect(.detailsChanged, fixture: fixture)
        XCTAssertEqual(fixture.submissions, 0)
    }
    func testDuplicateAppearingAfterOpeningDetailsStopsSubmission() async {
        let fixture = SyntheticAccess()
        fixture.introduceDuplicate = true
        await expect(.ambiguous, fixture: fixture)
        XCTAssertEqual(fixture.submissions, 0)
    }
    func testMultipleDetailsSheetsStopSubmission() async {
        let fixture = SyntheticAccess()
        fixture.extraSheet = true
        await expect(.unsupportedInterface, fixture: fixture)
        XCTAssertEqual(fixture.submissions, 0)
    }
    func testUnknownSheetIsNeverDismissed() async {
        let fixture = SyntheticAccess()
        fixture.tree[1]?.children.append(20)
        fixture.tree[20] = .init(text: ["AXRole": "AXSheet"])
        await expect(.unsupportedInterface, fixture: fixture)
        XCTAssertTrue(fixture.invocations.isEmpty)
    }
    func testDisabledSoundCannotBePressed() async {
        let fixture = SyntheticAccess()
        fixture.soundEnabled = 0
        await expect(.unavailableAction, fixture: fixture)
        XCTAssertEqual(fixture.submissions, 0)
    }
    func testUnrecognizedOnStateCannotBePressed() async {
        let fixture = SyntheticAccess()
        fixture.soundLabel = "Play Sound,On"
        await expect(.unavailableAction, fixture: fixture)
        XCTAssertEqual(fixture.submissions, 0)
    }
    func testFailedSubmissionIsUncertainAndNeverRetried() async {
        let fixture = SyntheticAccess()
        fixture.submitFails = true
        await expect(.requestUncertain, fixture: fixture)
        XCTAssertEqual(fixture.submissions, 1)
    }
    func testDeadlineStopsBeforeSubmission() async {
        let fixture = SyntheticAccess()
        fixture.timeoutOnOpen = true
        await expect(.discoveryTimedOut, fixture: fixture)
        XCTAssertEqual(fixture.submissions, 0)
    }
    func testCancellationStopsBeforeSubmission() async {
        let fixture = SyntheticAccess()
        fixture.pauseCancels = true
        do { try await FindMyAutomation(access: fixture).play(on: "Test Phone"); XCTFail("Expected cancellation") }
        catch { XCTAssertTrue(error is CancellationError) }
        XCTAssertEqual(fixture.submissions, 0)
    }
    func testPermissionFailurePerformsNoActions() async {
        let fixture = SyntheticAccess()
        fixture.permission = false
        await expect(.permission, fixture: fixture)
        XCTAssertTrue(fixture.invocations.isEmpty)
    }
    func testDevicesTabIsSelectedBeforeDiscovery() async throws {
        let fixture = SyntheticAccess()
        fixture.tree[3]?.numbers["AXValue"] = 0
        let names = try await FindMyAutomation(access: fixture).devices()
        XCTAssertEqual(names, ["Test Phone", "Test Watch"])
        XCTAssertEqual(fixture.invocations.map { $0.0 }, [3])
        XCTAssertEqual(fixture.submissions, 0)
    }
    func testWaitsForDevicesTabDuringWindowTransition() async throws {
        let fixture = SyntheticAccess()
        fixture.missingTabReads = 2
        let names = try await FindMyAutomation(access: fixture).devices()
        XCTAssertEqual(names, ["Test Phone", "Test Watch"])
        XCTAssertTrue(fixture.invocations.isEmpty)
    }

    func testDiagnosticDoesNotLaunchOrNavigate() async throws {
        let fixture = SyntheticAccess()
        fixture.tree[3]?.numbers["AXValue"] = 0
        fixture.tree[1]?.children.append(20)
        fixture.tree[20] = .init(text: ["AXRole": "AXSheet"])
        let report = try await FindMyAutomation(access: fixture).diagnose(selection: "Test Phone")
        XCTAssertTrue(report.contains("Matching device rows: 1"))
        XCTAssertTrue(report.contains("AXSheet: 1"))
        XCTAssertEqual(fixture.launches, 0)
        XCTAssertTrue(fixture.invocations.isEmpty)
    }
    func testDiagnosticShowsLastCleanupEvenAfterFindMyExitsWithoutLaunching() async throws {
        let fixture = SyntheticAccess()
        fixture.running = false
        fixture.lastOperation = FindMySessionReport(outcome: .playing, launched: true, initiallyHidden: false,
                                                   activated: false, cleanup: .quitConfirmed)
        let report = try await FindMyAutomation(access: fixture).diagnose(selection: "Test Phone")
        XCTAssertTrue(report.contains("Playback observed: true"))
        XCTAssertTrue(report.contains("Normal quit confirmed"))
        XCTAssertTrue(report.contains("not running"))
        XCTAssertFalse(report.contains("Test Phone"))
        XCTAssertEqual(fixture.launches, 0)
        XCTAssertTrue(fixture.invocations.isEmpty)
        XCTAssertTrue(fixture.outcomes.isEmpty)
    }

    func testDiagnosticDoesNotChangeOrActOnTheLastCleanupDecision() async throws {
        let fixture = SyntheticAccess()
        let outcome = FindMySessionReport(outcome: .submitted, launched: true, initiallyHidden: false,
                                         activated: false, cleanup: .keptPending)
        fixture.lastOperation = outcome
        let controller = FindMyAutomation(access: fixture)
        for _ in 0..<2 {
            let report = try await controller.diagnose(selection: "Test Phone")
            XCTAssertTrue(report.contains("Kept open: playback not observed"))
            XCTAssertFalse(report.contains("Test Phone"))
        }
        XCTAssertEqual(fixture.lastOperation, outcome)
        XCTAssertTrue(fixture.invocations.isEmpty)
        XCTAssertTrue(fixture.outcomes.isEmpty)
        XCTAssertEqual(fixture.launches, 0)
    }

    func testDiagnosticDoesNotLaunchMissingApp() async throws {
        let fixture = SyntheticAccess()
        fixture.running = false
        let report = try await FindMyAutomation(access: fixture).diagnose(selection: "Test Phone")
        XCTAssertTrue(report.contains("not running"))
        XCTAssertEqual(fixture.launches, 0)
        XCTAssertTrue(fixture.invocations.isEmpty)
    }
    func testDiagnosticOmitsPersonalTextEvenInUnexpectedAttributes() async throws {
        let fixture = SyntheticAccess()
        let privateText = "Fictional Person, 123 Example Street, sample@example.invalid"
        fixture.detailsName = privateText
        fixture.soundLabel = privateText
        try fixture.perform("Open Details", on: 5)
        fixture.invocations = []
        fixture.tree[13]?.text["AXTitle"] = privateText
        fixture.tree[13]?.text["AXValue"] = privateText
        fixture.tree[13]?.text["AXRole"] = privateText
        fixture.tree[5]?.actions = [privateText]
        let report = try await FindMyAutomation(access: fixture).diagnose(selection: "Test Phone")
        for forbidden in [privateText, "Fictional Person", "Example Street", "sample@example.invalid", "Test Phone", "Test Watch", "Synthetic status"] {
            XCTAssertFalse(report.contains(forbidden))
        }
        XCTAssertTrue(report.contains("other text (omitted)"))
        XCTAssertTrue(report.contains("description matches selection: false"))
        XCTAssertTrue(fixture.invocations.isEmpty)
    }
    func testDiagnosticFindsButtonTypesAndHeaderMatchWithoutPressing() async throws {
        let fixture = SyntheticAccess()
        fixture.headerInValue = true
        try fixture.perform("Open Details", on: 5)
        fixture.invocations = []
        let report = try await FindMyAutomation(access: fixture).diagnose(selection: "Test Phone")
        XCTAssertTrue(report.contains("value matches selection: true"))
        XCTAssertTrue(report.contains("AXDescription: text: Play Sound,Off"))
        XCTAssertTrue(report.contains("AXEnabled: number 1"))
        XCTAssertTrue(fixture.invocations.isEmpty)
    }
    func testDiagnosticHandlesCyclesAndSkipsMapContents() async throws {
        let fixture = SyntheticAccess()
        fixture.tree[1]?.children += [0,21]
        fixture.tree[21] = .init(text: ["AXRole": "AXImage"], children: [22])
        fixture.tree[22] = .init(text: ["AXRole": "AXSheet"])
        let report = try await FindMyAutomation(access: fixture).diagnose(selection: "")
        XCTAssertTrue(report.contains("Scan complete: true"))
        XCTAssertFalse(report.contains("AXSheet:"))
        XCTAssertTrue(fixture.invocations.isEmpty)
    }
    func testDiagnosticClassifiesOnlyFixedStringsAndExactNumbers() {
        XCTAssertEqual(DiagnosticValue.classify("Play Sound, Off" as NSString).summary, "text with whitespace: Play Sound,Off")
        XCTAssertEqual(DiagnosticValue.classify(kCFBooleanTrue).summary, "boolean true")
        XCTAssertEqual(DiagnosticValue.classify(NSNumber(value: 1.5)).summary, "other number")
        XCTAssertEqual(DiagnosticValue.classify(["private": "text"] as NSDictionary).summary, "other type (omitted)")
    }
    func testDiagnosticStopsAtDeadlineWithoutActions() async throws {
        let fixture = SyntheticAccess()
        fixture.advanceClockOnRead = true
        let report = try await FindMyAutomation(access: fixture).diagnose(selection: "Test Phone")
        XCTAssertTrue(report.contains("Scan complete: false"))
        XCTAssertTrue(fixture.invocations.isEmpty)
    }
    func testDiagnosticPermissionDenialDoesNotLaunchOrAct() async {
        let fixture = SyntheticAccess()
        fixture.permission = false
        do {
            _ = try await FindMyAutomation(access: fixture).diagnose(selection: "Test Phone")
            XCTFail("Expected permission denial")
        } catch { XCTAssertEqual(error as? PingError, .permission) }
        XCTAssertEqual(fixture.launches, 0)
        XCTAssertTrue(fixture.invocations.isEmpty)
    }
}

@MainActor final class FindMyQuitPreparationTests: XCTestCase {
    private func fixture() throws -> SyntheticAccess {
        let f = SyntheticAccess()
        try f.perform("Open Details", on: 5)
        try f.perform("AXPress", on: 13)
        f.invocations = []
        return f
    }
    private func dismiss(_ f: SyntheticAccess, allowed: @MainActor () -> Bool = { true }) async -> Bool {
        await FindMyQuitPreparation(access: f).dismissDetails(in: 0, name: "Test Phone", isAllowed: allowed)
    }

    func testClosesOnlyVerifiedPlayingDetailsAndWaitsForDismissal() async throws {
        let f = try fixture()
        let ready = await dismiss(f)
        XCTAssertTrue(ready)
        XCTAssertEqual(f.invocations.map(\.0), [14])
        XCTAssertEqual(f.submissions, 0)
    }
    func testChangedOrConflictingDeviceNamePreventsClosing() async throws {
        for key in ["AXValue", "AXDescription"] {
            let f = try fixture()
            f.tree[12]?.text[key] = "Another Test Phone"
            let ready = await dismiss(f)
            XCTAssertFalse(ready)
            XCTAssertTrue(f.invocations.isEmpty)
        }
    }
    func testDisabledOrAmbiguousCloseControlNeverGuesses() async throws {
        for ambiguous in [false, true] {
            let f = try fixture()
            if ambiguous {
                f.tree[15] = f.tree[14]
                f.tree[10]?.children.append(15)
            } else { f.tree[14]?.numbers["AXEnabled"] = 0 }
            let ready = await dismiss(f)
            XCTAssertFalse(ready)
            XCTAssertTrue(f.invocations.isEmpty)
        }
    }
    func testUnknownOrMultipleSheetsAreLeftAlone() async throws {
        for multiple in [false, true] {
            let f = try fixture()
            if multiple {
                f.tree[15] = .init(text: ["AXRole": "AXSheet"])
                f.tree[1]?.children.append(15)
            } else { f.tree[10]?.children = [] }
            let ready = await dismiss(f)
            XCTAssertFalse(ready)
            XCTAssertTrue(f.invocations.isEmpty)
        }
    }
    func testPlaybackMustStillMatchBeforeClosing() async throws {
        let f = try fixture()
        f.tree[13]?.text["AXDescription"] = "Play Sound,Off"
        let ready = await dismiss(f)
        XCTAssertFalse(ready)
        XCTAssertTrue(f.invocations.isEmpty)
    }
    func testCloseFailureIsNeverRetried() async throws {
        let f = try fixture()
        f.closeFails = true
        let ready = await dismiss(f)
        XCTAssertFalse(ready)
        XCTAssertEqual(f.invocations.map(\.0), [14])
    }
    func testIgnoredCloseTimesOutWithoutAnotherAction() async throws {
        let f = try fixture()
        f.keepsDetailsAfterClose = true
        let start = f.now
        let ready = await dismiss(f)
        XCTAssertFalse(ready)
        XCTAssertEqual(f.invocations.map(\.0), [14])
        XCTAssertEqual(start.duration(to: f.now), .seconds(2))
    }
    func testOwnershipAndActivationAreRecheckedImmediatelyBeforeClose() async throws {
        let f = try fixture()
        var checks = 0
        let ready = await dismiss(f) { checks += 1; return checks == 1 }
        XCTAssertFalse(ready)
        XCTAssertTrue(f.invocations.isEmpty)
        XCTAssertEqual(checks, 2)
    }
    func testActivationWhileSheetClosesStopsCleanup() async throws {
        let f = try fixture()
        var allowed = true
        f.onClose = { allowed = false }
        let ready = await dismiss(f, allowed: { allowed })
        XCTAssertFalse(ready)
        XCTAssertEqual(f.invocations.map(\.0), [14])
    }
    func testAnAlreadyDismissedSheetNeedsNoUIAction() async {
        let f = SyntheticAccess()
        let ready = await dismiss(f)
        XCTAssertTrue(ready)
        XCTAssertTrue(f.invocations.isEmpty)
    }
    func testUnexpectedDialogPreventsQuitPreparation() async {
        let f = SyntheticAccess()
        f.tree[1]?.text["AXSubrole"] = "AXDialog"
        let ready = await dismiss(f)
        XCTAssertFalse(ready)
        XCTAssertTrue(f.invocations.isEmpty)
    }

    func testMissingWindowTreeIsNotTreatedAsConfirmedDismissal() async {
        let f = SyntheticAccess()
        f.tree[0]?.children = []
        let ready = await dismiss(f)
        XCTAssertFalse(ready)
        XCTAssertTrue(f.invocations.isEmpty)
    }
}
