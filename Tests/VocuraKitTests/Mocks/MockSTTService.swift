import Foundation
@testable import VocuraKit

/// Mock STT service for testing. Returns a predefined transcription result.
class MockSTTService: SpeechToTextService {
    var result: Result<String, Error> = .success("")
    var transcribeCallCount = 0
    var lastAudioURL: URL?

    func transcribe(audioURL: URL, completion: @escaping (Result<String, Error>) -> Void) {
        transcribeCallCount += 1
        lastAudioURL = audioURL
        completion(result)
    }
}
