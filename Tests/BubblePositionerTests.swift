import XCTest
import AppKit
@testable import Vocura

/// Tests for the floating indicator's on-screen positioning
final class BubblePositionerTests: XCTestCase {

    func testIndicatorIsCenteredHorizontally() {
        let screenFrame = NSRect(x: 0, y: 0, width: 1000, height: 800)
        let windowSize = NSSize(width: 200, height: 100)

        let origin = BubblePositioner.origin(screenFrame: screenFrame, windowSize: windowSize)

        // Horizontal center: (1000 - 200) / 2 = 400
        XCTAssertEqual(origin.x, 400, "Indicator should be horizontally centered")
    }

    func testIndicatorSitsAtBottomWithInset() {
        let screenFrame = NSRect(x: 0, y: 0, width: 1000, height: 800)
        let windowSize = NSSize(width: 200, height: 100)

        let origin = BubblePositioner.origin(screenFrame: screenFrame, windowSize: windowSize)

        // Bottom edge plus the 20pt inset
        XCTAssertEqual(origin.y, 20, "Indicator should sit at the bottom with a 20pt inset")
    }

    func testCenteringRespectsScreenOrigin() {
        // Secondary display offset from the main screen origin
        let screenFrame = NSRect(x: 500, y: 300, width: 1000, height: 800)
        let windowSize = NSSize(width: 200, height: 100)

        let origin = BubblePositioner.origin(screenFrame: screenFrame, windowSize: windowSize)

        XCTAssertEqual(origin.x, 500 + 400, "Centering should account for the screen's x origin")
        XCTAssertEqual(origin.y, 300 + 20, "Bottom inset should account for the screen's y origin")
    }
}
