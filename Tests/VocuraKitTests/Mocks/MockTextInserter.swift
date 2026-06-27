import Foundation
@testable import VocuraKit

/// Mock TextInserter for testing. Captures inserted text without touching the pasteboard.
class MockTextInserter: TextInserting {
    var insertCallCount = 0
    var lastInsertedText: String?
    var onInsert: ((String) -> Void)?

    func insert(_ text: String) {
        insertCallCount += 1
        lastInsertedText = text
        onInsert?(text)
    }
}
