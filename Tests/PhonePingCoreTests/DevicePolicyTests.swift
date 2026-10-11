import XCTest
@testable import PhonePingCore

final class DevicePolicyTests: XCTestCase {
    func testDuplicateNamesCannotTriggerEitherDevice() {
        XCTAssertThrowsError(try DevicePolicy.uniqueIndex(named: "iPhone", in: ["Mac", "iPhone", "iPhone"])) {
            XCTAssertEqual($0 as? PingError, .ambiguous)
        }
    }

    func testPeriodDistinguishesExactDevice() throws {
        XCTAssertEqual(try DevicePolicy.uniqueIndex(named: "iPhone.", in: ["iPhone", "iPhone."]), 1)
    }

    func testDoesNotFallBackToPartialMatch() {
        XCTAssertThrowsError(try DevicePolicy.uniqueIndex(named: "iPhone", in: ["iPhone Pro"])) {
            XCTAssertEqual($0 as? PingError, .notFound)
        }
    }

    func testNeverSelectsFirstDeviceWhenTargetMissing() {
        XCTAssertThrowsError(try DevicePolicy.uniqueIndex(named: "My phone", in: ["Another phone"]))
        XCTAssertThrowsError(try DevicePolicy.uniqueIndex(named: "My phone", in: []))
    }

    func testLocationAndBatterySuffixAreDiscarded() {
        XCTAssertEqual(DevicePolicy.name(from: "iPhone., Nearby, Example Street, 80 percent"), "iPhone.")
    }

    func testDangerousOrUnexpectedActionsAreNotAccepted() {
        for action in ["Erase", "Remove This Device…", "Lost Mode", "Stop Playing", "Play Sound and Erase", "Replay", "play", "", "AXPress"] {
            XCTAssertFalse(DevicePolicy.isPlayAction(action), action)
        }
        XCTAssertTrue(DevicePolicy.isPlayAction("Play"))
        XCTAssertTrue(DevicePolicy.isPlayAction("Play Sound"))
    }

    func testRejectsAmbiguousNameDelimiters() {
        for name in ["", "   ", "Phone, Work", "Phone\nWork"] {
            XCTAssertThrowsError(try DevicePolicy.validate(name))
        }
    }

    func testCaseIsNotSilentlyFolded() throws {
        XCTAssertEqual(try DevicePolicy.uniqueIndex(named: "iphone", in: ["iPhone", "iphone"]), 1)
    }

    func testDetailsMustConfirmTheFullDeviceName() {
        XCTAssertFalse(DevicePolicy.canPlay(expectedName: "iPhone", detailNames: ["iPhone, Work"], buttonLabel: "Play Sound,Off", enabled: true))
        XCTAssertFalse(DevicePolicy.canPlay(expectedName: "iPhone", detailNames: [], buttonLabel: "Play Sound,Off", enabled: true))
        XCTAssertFalse(DevicePolicy.canPlay(expectedName: "iPhone", detailNames: ["iPhone", "iPhone"], buttonLabel: "Play Sound,Off", enabled: true))
        XCTAssertTrue(DevicePolicy.canPlay(expectedName: "iPhone.", detailNames: ["iPhone."], buttonLabel: "Play Sound,Off", enabled: true))
    }

    func testDisabledOrAlreadyPlayingButtonsAreRejected() {
        XCTAssertFalse(DevicePolicy.canPlay(expectedName: "Phone", detailNames: ["Phone"], buttonLabel: "Play Sound,Off", enabled: false))
        for label in ["Play Sound,On", "Directions,Off", "Erase,Off", "Play Sound,Off,Erase", "Play Sound"] {
            XCTAssertFalse(DevicePolicy.canPlay(expectedName: "Phone", detailNames: ["Phone"], buttonLabel: label, enabled: true))
        }
    }
}
