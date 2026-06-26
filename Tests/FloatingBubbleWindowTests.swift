import XCTest
import AppKit
@testable import Vocura

/// Tests for the floating indicator window's behavior
final class FloatingBubbleWindowTests: XCTestCase {

    func testWindowIsNotMovable() {
        let window = FloatingBubbleWindow(contentRect: NSRect(x: 0, y: 0, width: 200, height: 100))

        XCTAssertFalse(window.isMovableByWindowBackground, "Indicator must not be draggable by its background")
        XCTAssertFalse(window.isMovable, "Indicator must not be movable")
    }
}
