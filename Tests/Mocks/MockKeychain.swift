import Foundation
@testable import VocuraCore

/// Mock Keychain implementation for testing. Stores values in memory.
class MockKeychain: KeychainServiceProtocol {
    private var storage: String?
    
    /// Value to return from load(). Set before test.
    var mockValue: String?
    
    /// Tracks if save was called
    var saveCallCount = 0
    var lastSavedValue: String?
    
    /// Tracks if delete was called
    var deleteCallCount = 0
    
    func save(_ value: String) -> Bool {
        saveCallCount += 1
        lastSavedValue = value
        storage = value
        return true
    }
    
    func load() -> String? {
        return mockValue ?? storage
    }
    
    func delete() {
        deleteCallCount += 1
        storage = nil
    }
    
    /// Reset all state for clean test setup
    func reset() {
        storage = nil
        mockValue = nil
        saveCallCount = 0
        lastSavedValue = nil
        deleteCallCount = 0
    }
}
