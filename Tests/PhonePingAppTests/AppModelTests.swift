import XCTest
import AppKit
import PhonePingCore
@testable import PhonePing

private final class MemoryPreferences: UserDefaults, @unchecked Sendable {
    private var storage: [String: Any] = [:]
    override func string(forKey key: String) -> String? { storage[key] as? String }
    override func set(_ value: Any?, forKey key: String) { storage[key] = value }
}

private actor FakeFindMy: FindMyService {
    var names: [String]
    var playResult: FindMySoundResult
    var playError: PingError?
    var readError: PingError?
    private(set) var reads = 0
    private(set) var played: [String] = []
    private(set) var diagnostics = 0
    init(names: [String] = [], playError: PingError? = nil, playResult: FindMySoundResult = .submitted) {
        self.names = names
        self.playError = playError
        self.playResult = playResult
    }
    func devices() async throws -> [String] {
        reads += 1
        if let readError { throw readError }
        return names
    }
    func play(on name: String) async throws -> FindMySoundResult {
        played.append(name)
        if let playError { throw playError }
        return playResult
    }
    func failReading() { readError = .unsupportedInterface }
    func diagnose(selection: String) async throws -> String {
        diagnostics += 1
        return "Synthetic control report"
    }
}

final class AppModelTests: XCTestCase {
    @MainActor func testSelectionChangeUpdatesStatusAndClearsOldResult() async {
        let preferences = MemoryPreferences()
        let service = FakeFindMy()
        let model = AppModel(preferences: preferences, controller: service, permissionCheck: { true })
        model.phoneName = "Test Phone A"
        model.ping()
        await model.waitForOperation()
        XCTAssertFalse(model.message.isEmpty)
        var observedName = ""
        model.stateChanged = { observedName = model.phoneName }
        model.phoneName = "Test Phone B"
        XCTAssertEqual(observedName, "Test Phone B")
        XCTAssertEqual(preferences.string(forKey: "phoneName"), "Test Phone B")
        XCTAssertEqual(model.message, "")
    }

    @MainActor func testRefreshBlocksPreviouslySavedDuplicate() async {
        let preferences = MemoryPreferences()
        preferences.set("Test Phone", forKey: "phoneName")
        let service = FakeFindMy(names: ["Test Phone", "Test Phone"])
        let model = AppModel(preferences: preferences, controller: service, permissionCheck: { true })
        model.refresh()
        await model.waitForOperation()
        XCTAssertEqual(model.selectionIssue, .ambiguous)
        XCTAssertFalse(model.ready)
        model.ping()
        await model.waitForOperation()
        let played = await service.played
        XCTAssertTrue(played.isEmpty)
    }

    @MainActor func testPermissionRevocationUpdatesStatusAndPreventsRequest() async {
        var permitted = true
        let service = FakeFindMy()
        let model = AppModel(preferences: MemoryPreferences(), controller: service, permissionCheck: { permitted })
        model.phoneName = "Test Phone"
        var updates = 0
        model.stateChanged = { updates += 1 }
        permitted = false
        model.checkPermission()
        XCTAssertEqual(updates, 1)
        XCTAssertFalse(model.ready)
        model.ping()
        await model.waitForOperation()
        let played = await service.played
        XCTAssertTrue(played.isEmpty)
    }

    @MainActor func testRapidClicksSubmitOneRequest() async {
        let service = FakeFindMy()
        let model = AppModel(preferences: MemoryPreferences(), controller: service, permissionCheck: { true })
        model.phoneName = "Test Phone"
        model.ping()
        model.ping()
        model.ping()
        await model.waitForOperation()
        let played = await service.played
        XCTAssertEqual(played, ["Test Phone"])
    }

    @MainActor func testUncertainRequestIsNotRetriedOrBroughtToFront() async {
        let service = FakeFindMy(playError: .requestUncertain)
        let model = AppModel(preferences: MemoryPreferences(), controller: service, permissionCheck: { true })
        var reveals = 0
        model.revealSettings = { reveals += 1 }
        model.phoneName = "Test Phone"
        model.ping()
        await model.waitForOperation()
        let played = await service.played
        XCTAssertEqual(played.count, 1)
        XCTAssertTrue(model.failed)
        XCTAssertEqual(model.message, PingError.requestUncertain.localizedDescription)
        XCTAssertEqual(reveals, 0)
    }

    @MainActor func testSuccessfulRequestDoesNotRevealSettings() async {
        let service = FakeFindMy()
        let model = AppModel(preferences: MemoryPreferences(), controller: service, permissionCheck: { true })
        var reveals = 0
        model.revealSettings = { reveals += 1 }
        model.phoneName = "Test Phone"
        model.ping()
        await model.waitForOperation()
        XCTAssertFalse(model.failed)
        XCTAssertEqual(reveals, 0)
        XCTAssertEqual(model.statusSummary, "Sound requested in Find My")
    }

    @MainActor func testExistingPlaybackIsInformationalAndDoesNotRevealSettings() async {
        let service = FakeFindMy(playResult: .alreadyPlaying)
        let model = AppModel(preferences: MemoryPreferences(), controller: service, permissionCheck: { true })
        var reveals = 0
        model.revealSettings = { reveals += 1 }
        model.phoneName = "Test Phone"
        model.ping()
        await model.waitForOperation()
        XCTAssertFalse(model.failed)
        XCTAssertFalse(model.busy)
        XCTAssertEqual(reveals, 0)
        XCTAssertEqual(model.statusSummary, "Sound already playing")
        XCTAssertEqual(model.message, "Find My reports that a sound is already playing on this device.")
        let played = await service.played
        XCTAssertEqual(played, ["Test Phone"])
    }

    @MainActor func testEmptyRefreshExplainsRecoveryWithoutOfferingSound() async {
        let service = FakeFindMy()
        let model = AppModel(preferences: MemoryPreferences(), controller: service, permissionCheck: { true })
        model.refresh()
        await model.waitForOperation()
        XCTAssertEqual(model.statusSummary, "No devices found")
        XCTAssertEqual(model.statusText, "Open Find My to check your devices, then refresh the list.")
        XCTAssertFalse(model.ready)
        let menu = PhonePingMenu(model: model, showSettings: {}, showAbout: {}, quit: {})
        XCTAssertEqual(menu.menu.items[1].title, "No devices found")
        XCTAssertFalse(menu.menu.items[0].isEnabled)
        let played = await service.played
        XCTAssertTrue(played.isEmpty)
        model.forget()
        XCTAssertEqual(model.statusSummary, "Choose a device in Settings")
    }

    @MainActor func testFailedRefreshDiscardsStaleDeviceSnapshot() async {
        let service = FakeFindMy(names: ["Test Phone"])
        let model = AppModel(preferences: MemoryPreferences(), controller: service, permissionCheck: { true })
        model.refresh()
        await model.waitForOperation()
        XCTAssertTrue(model.hasLoadedDevices)
        await service.failReading()
        model.refresh()
        await model.waitForOperation()
        XCTAssertTrue(model.devices.isEmpty)
        XCTAssertFalse(model.hasLoadedDevices)
        XCTAssertTrue(model.failed)
    }

    @MainActor func testOpeningMenuNeverDiscoversDevicesOrPlaysSound() async {
        let service = FakeFindMy()
        let model = AppModel(preferences: MemoryPreferences(), controller: service, permissionCheck: { true })
        model.phoneName = "Test Phone"
        let controller = PhonePingMenu(model: model, showSettings: {}, showAbout: {}, quit: {})
        for _ in 0..<3 { controller.menuNeedsUpdate(controller.menu) }
        await model.waitForOperation()
        let reads = await service.reads
        let played = await service.played
        XCTAssertEqual(reads, 0)
        XCTAssertTrue(played.isEmpty)
        XCTAssertTrue(controller.menu.items[0].isEnabled)
    }

    @MainActor func testMenuAccessibilityKeepsFullTargetWhenTitleIsTruncated() {
        let model = AppModel(preferences: MemoryPreferences(), controller: FakeFindMy(), permissionCheck: { true })
        let longName = "A fictional device name with the distinguishing suffix at the end"
        model.phoneName = longName
        let controller = PhonePingMenu(model: model, showSettings: {}, showAbout: {}, quit: {})
        let item = controller.menu.items[0]
        XCTAssertFalse(item.title.contains(longName))
        XCTAssertEqual(item.accessibilityLabel(), "Play Sound on " + longName)
        model.phoneName = "Second Test Phone"
        controller.update()
        XCTAssertEqual(item.accessibilityLabel(), "Play Sound on Second Test Phone")
        model.forget()
        controller.update()
        XCTAssertEqual(item.accessibilityLabel(), "Play Sound")
    }

    @MainActor func testMenuReflectsRevokedPermissionBeforeOfferingSound() async {
        var permitted = true
        let service = FakeFindMy()
        let model = AppModel(preferences: MemoryPreferences(), controller: service, permissionCheck: { permitted })
        model.phoneName = "Test Phone"
        let controller = PhonePingMenu(model: model, showSettings: {}, showAbout: {}, quit: {})
        permitted = false
        controller.menuNeedsUpdate(controller.menu)
        XCTAssertFalse(controller.menu.items[0].isEnabled)
        XCTAssertFalse(controller.menu.items[1].isHidden)
        let played = await service.played
        XCTAssertTrue(played.isEmpty)
    }

    @MainActor func testRefreshFailureIsVisibleBeforeSelectingADevice() async {
        let service = FakeFindMy()
        let model = AppModel(preferences: MemoryPreferences(), controller: service, permissionCheck: { true })
        await service.failReading()
        model.refresh()
        await model.waitForOperation()
        XCTAssertTrue(model.phoneName.isEmpty)
        XCTAssertEqual(model.statusText, PingError.unsupportedInterface.localizedDescription)
        XCTAssertEqual(model.statusSummary, PingError.unsupportedInterface.title)
    }


    @MainActor func testRestoredPermissionClearsObsoletePermissionError() async {
        let service = FakeFindMy(playError: .permission)
        let model = AppModel(preferences: MemoryPreferences(), controller: service, permissionCheck: { true })
        model.phoneName = "Test Phone"
        model.ping()
        await model.waitForOperation()
        XCTAssertFalse(model.hasPermission)
        XCTAssertTrue(model.failed)
        model.checkPermission()
        XCTAssertTrue(model.hasPermission)
        XCTAssertFalse(model.failed)
        XCTAssertTrue(model.statusSummary.isEmpty)
        XCTAssertTrue(model.ready)
    }

    @MainActor func testDiagnosticPreservesFailureAndDoesNotRing() async {
        let service = FakeFindMy(playError: .unavailableAction)
        let model = AppModel(preferences: MemoryPreferences(), controller: service, permissionCheck: { true })
        model.phoneName = "Test Phone"
        model.ping()
        await model.waitForOperation()
        let originalMessage = model.message
        model.runDiagnostic()
        model.runDiagnostic()
        model.ping()
        await model.waitForOperation()
        let diagnostics = await service.diagnostics
        let played = await service.played
        XCTAssertEqual(diagnostics, 1)
        XCTAssertEqual(played.count, 1)
        XCTAssertEqual(model.message, originalMessage)
        XCTAssertTrue(model.failed)
        XCTAssertEqual(model.diagnosticReport, "Synthetic control report")
        model.clearDiagnostic()
        XCTAssertTrue(model.diagnosticReport.isEmpty)
    }
    @MainActor func testDiagnosticRequiresPermissionAndNeverRunsFromMenu() async {
        let service = FakeFindMy()
        let model = AppModel(preferences: MemoryPreferences(), controller: service, permissionCheck: { false })
        let controller = PhonePingMenu(model: model, showSettings: {}, showAbout: {}, quit: {})
        controller.menuNeedsUpdate(controller.menu)
        model.runDiagnostic()
        await model.waitForOperation()
        let count = await service.diagnostics
        XCTAssertEqual(count, 0)
        XCTAssertTrue(model.diagnosticReport.isEmpty)
    }

}
