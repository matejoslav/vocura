import XCTest
import Foundation
@testable import Vocura

/// Tests for SettingsManager registering hotkeys via an injected hotkey manager.
final class HotkeyRegistrationTests: XCTestCase {

    func testSettingHotkeyRegistersWithManager() {
        let mockHotkey = MockHotkeyManager()
        let manager = SettingsManager(keychainService: MockKeychain(), hotkeyManager: mockHotkey)

        manager.hotkey = KeyShortcut(keyCode: 49, modifiers: 0)

        XCTAssertGreaterThanOrEqual(mockHotkey.registerCallCount, 1)
        XCTAssertEqual(mockHotkey.lastShortcut, KeyShortcut(keyCode: 49, modifiers: 0))
    }

    func testRegisterHotkeyClearsPreviousRegistrations() {
        let mockHotkey = MockHotkeyManager()
        let manager = SettingsManager(keychainService: MockKeychain(), hotkeyManager: mockHotkey)
        let before = mockHotkey.unregisterAllCallCount

        manager.registerHotkey()

        XCTAssertEqual(mockHotkey.unregisterAllCallCount, before + 1)
    }

    func testTriggeredHotkeyInvokesHotkeyAction() {
        let mockHotkey = MockHotkeyManager()
        let manager = SettingsManager(keychainService: MockKeychain(), hotkeyManager: mockHotkey)
        var fired = false
        manager.hotkeyAction = { fired = true }

        manager.hotkey = KeyShortcut(keyCode: 49, modifiers: 0)
        mockHotkey.lastAction?()

        XCTAssertTrue(fired)
    }
}
