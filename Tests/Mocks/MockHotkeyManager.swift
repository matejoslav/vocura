import Foundation
@testable import Vocura

/// Mock hotkey manager for testing. Captures registrations without touching Carbon APIs.
class MockHotkeyManager: HotkeyManaging {
    var registerCallCount = 0
    var unregisterAllCallCount = 0
    var lastShortcut: KeyShortcut?
    var lastAction: (() -> Void)?

    func register(shortcut: KeyShortcut, action: @escaping () -> Void) {
        registerCallCount += 1
        lastShortcut = shortcut
        lastAction = action
    }

    func unregisterAll() {
        unregisterAllCallCount += 1
    }
}
