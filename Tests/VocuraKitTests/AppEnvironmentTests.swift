import XCTest
@testable import VocuraKit

/// Tests for detecting the test environment, used to suppress real I/O at app launch.
final class AppEnvironmentTests: XCTestCase {

    func testIsRunningTestsIsTrueUnderXCTest() {
        XCTAssertTrue(Constants.Environment.isRunningTests)
    }
}
