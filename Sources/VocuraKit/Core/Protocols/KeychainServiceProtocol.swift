import Foundation

/// Protocol abstraction for Keychain operations, enabling dependency injection and testing.
public protocol KeychainServiceProtocol {
    func save(_ value: String) -> Bool
    func load() -> String?
    func delete()
}
