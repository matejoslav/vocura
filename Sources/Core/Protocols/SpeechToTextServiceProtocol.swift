import Foundation

/// Protocol abstraction for speech-to-text transcription, enabling dependency injection and testing.
public protocol SpeechToTextService {
    func transcribe(audioURL: URL, completion: @escaping (Result<String, Error>) -> Void)
}
