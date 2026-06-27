import Foundation
import Combine
@testable import VocuraKit

/// Mock AudioRecorder for testing. Records interactions without touching real audio hardware.
class MockAudioRecorder: AudioRecording {
    private let audioLevelSubject = CurrentValueSubject<Float, Never>(0.0)
    var audioLevelPublisher: AnyPublisher<Float, Never> { audioLevelSubject.eraseToAnyPublisher() }

    var audioFileURL: URL?

    var startCallCount = 0
    var stopCallCount = 0

    func start() {
        startCallCount += 1
    }

    func stop() {
        stopCallCount += 1
    }
}
