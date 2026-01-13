import AVFoundation
import Combine

class AudioRecorder: NSObject, ObservableObject {
    private var recorder: AVAudioRecorder?
    private var timer: Timer?
    
    @Published var audioLevel: Float = 0.0
    var audioFileURL: URL?
    
    override init() {
        super.init()
    }
    
    func start() {
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "recording_\(UUID().uuidString).m4a"
        audioFileURL = tempDir.appendingPathComponent(fileName)
        
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            recorder = try AVAudioRecorder(url: audioFileURL!, settings: settings)
            recorder?.isMeteringEnabled = true
            recorder?.record()
            
            startMetering()
        } catch {
            print("Failed to start recording: \(error)")
        }
    }
    
    func stop() {
        recorder?.stop()
        stopMetering()
    }
    
    private func startMetering() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.recorder?.updateMeters()
            if let level = self?.recorder?.averagePower(forChannel: 0) {
                // Normalize level from -60...0 to 0...1
                let normalized = max(0, (level + 60) / 60)
                DispatchQueue.main.async {
                    self?.audioLevel = normalized
                }
            }
        }
    }
    
    private func stopMetering() {
        timer?.invalidate()
        timer = nil
    }
}
