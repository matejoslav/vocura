import XCTest
import Foundation
@testable import Vocura

/// Tests for SettingsManager's API key persistence via an injected keychain.
final class SettingsManagerTests: XCTestCase {

    func testLoadsAPIKeyFromKeychainOnBootstrap() {
        let mockKeychain = MockKeychain()
        mockKeychain.mockValue = "stored-key"
        let manager = SettingsManager(keychainService: mockKeychain, hotkeyManager: MockHotkeyManager())

        manager.bootstrap()

        XCTAssertEqual(manager.apiKey, "stored-key")
    }

    func testApiKeyDefaultsToEmptyWhenKeychainEmpty() {
        let mockKeychain = MockKeychain()
        mockKeychain.mockValue = nil
        let manager = SettingsManager(keychainService: mockKeychain, hotkeyManager: MockHotkeyManager())

        manager.bootstrap()

        XCTAssertEqual(manager.apiKey, "")
    }

    func testSettingAPIKeySavesToKeychain() {
        let mockKeychain = MockKeychain()
        let manager = SettingsManager(keychainService: mockKeychain, hotkeyManager: MockHotkeyManager())

        manager.apiKey = "new-key"

        XCTAssertEqual(mockKeychain.lastSavedValue, "new-key")
    }
}
