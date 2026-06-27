import Foundation
import Combine

/// Protocol abstraction for audio recording, enabling dependency injection and testing.
public protocol AudioRecording: AnyObject {
    var audioLevelPublisher: AnyPublisher<Float, Never> { get }
    var audioFileURL: URL? { get }
    func start()
    func stop()
}
