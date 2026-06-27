import Foundation

/// Protocol abstraction for inserting text into the focused application, enabling dependency injection and testing.
public protocol TextInserting {
    func insert(_ text: String)
}
