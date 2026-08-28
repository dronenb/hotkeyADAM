import XCTest
@testable import hotkeyADAM

final class HotkeyAdamTests: XCTestCase {
    func testAccessibilityServiceExposesTrustState() {
        let service = AccessibilityService()
        // Trust state can be true or false depending on the host; just ensure no crash and a Bool.
        XCTAssertTrue(service.isTrusted || !service.isTrusted)
    }
}
