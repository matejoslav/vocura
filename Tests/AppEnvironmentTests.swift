import XCTest
@testable import Vocura

/// Tests for detecting the test environment, used to suppress real I/O at app launch.
final class AppEnvironmentTests: XCTestCase {

    func testIsRunningTestsIsTrueUnderXCTest() {
        XCTAssertTrue(Constants.Environment.isRunningTests)
    }
}
