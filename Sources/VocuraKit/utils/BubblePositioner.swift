import AppKit

/// Computes the on-screen origin for the floating indicator window.
enum BubblePositioner {
    static let bottomInset: CGFloat = 20

    static func origin(screenFrame: NSRect, windowSize: NSSize) -> NSPoint {
        let x = screenFrame.minX + (screenFrame.width - windowSize.width) / 2
        let y = screenFrame.minY + bottomInset
        return NSPoint(x: x, y: y)
    }
}
