import ApplicationServices
import XCTest
@testable import PhonePing

final class AccessibilityElementTests: XCTestCase {
    // A messaging timeout set on one AX reference does not apply to elements read from it.
    func testElementsReadThroughAWrapperKeepItsTimeout() {
        let app = AccessibilityElement(raw: AXUIElementCreateApplication(getpid()), timeout: 0.25)
        let child = app.adopting(AXUIElementCreateApplication(getpid()))
        XCTAssertEqual(child.timeout, 0.25)
        XCTAssertEqual(app.adopting(child.raw).timeout, 0.25)
    }

    func testIdentityIgnoresTimeout() {
        let raw = AXUIElementCreateApplication(getpid())
        let short = AccessibilityElement(raw: raw, timeout: 0.25)
        let long = AccessibilityElement(raw: raw, timeout: 1)
        XCTAssertEqual(short, long)
        XCTAssertEqual(Set([short, long]).count, 1)
    }
}
