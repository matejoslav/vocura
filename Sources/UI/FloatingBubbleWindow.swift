import SwiftUI
import AppKit
import Combine

class WindowManager: ObservableObject {
    static let shared = WindowManager()
    
    private var window: FloatingBubbleWindow?
    private let recorder = AudioRecorder()
    private let sttService = STTService()
    private let textInserter = TextInserter()
    
    @Published var isRecording = false
    @Published var isProcessing = false
    @Published var statusMessage: String?
    @Published var audioLevel: Float = 0.0
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupWindow()
        setupBindings()
    }
    
    private func setupBindings() {
        recorder.$audioLevel
            .receive(on: DispatchQueue.main)
            .assign(to: \.audioLevel, on: self)
            .store(in: &cancellables)
    }
    
    private func setupWindow() {
        let bubbleView = BubbleView(viewModel: self)
        let hostingView = NSHostingView(rootView: bubbleView)
        
        let window = FloatingBubbleWindow(contentRect: NSRect(x: 0, y: 0, width: 200, height: 100))
        window.contentView = hostingView
        self.window = window
        
        // Listen for internal layout changes in the hosting view
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        
        // Update window size whenever state changes that might affect the view's size
        self.$isRecording
            .combineLatest(self.$isProcessing, self.$statusMessage)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateWindowSize()
            }
            .store(in: &cancellables)
    }
    
    private func updateWindowSize() {
        guard let window = window, let hostingView = window.contentView as? NSHostingView<BubbleView> else { return }
        
        // Calculate fitting size
        let fittingSize = hostingView.fittingSize
        
        // Keep the indicator centered along the bottom of the screen
        if let screen = NSScreen.main {
            let origin = BubblePositioner.origin(screenFrame: screen.visibleFrame, windowSize: fittingSize)
            let newFrame = NSRect(origin: origin, size: fittingSize)
            window.setFrame(newFrame, display: true, animate: true)
        }
    }
    
    func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }
    
    func startRecording() {
        isRecording = true
        isProcessing = false
        statusMessage = nil
        window?.show()
        recorder.start()
    }
    
    func stopRecording() {
        isRecording = false
        isProcessing = true
        recorder.stop()
        
        if let url = recorder.audioFileURL {
            sttService.transcribe(audioURL: url) { [weak self] result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let text):
                        self?.showResult(text)
                    case .failure(let error):
                        self?.showError(error.localizedDescription)
                    }
                }
            }
        }
    }
    
    func showResult(_ text: String) {
        isProcessing = false
        textInserter.insert(text)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.window?.hide()
        }
    }
    
    func showError(_ message: String) {
        isProcessing = false
        isRecording = false
        statusMessage = message
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.window?.hide()
        }
    }
}

class FloatingBubbleWindow: NSPanel {
    init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        self.isFloatingPanel = true
        self.level = .floating
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        self.isMovableByWindowBackground = false
        self.isMovable = false
        self.backgroundColor = .clear
        self.hasShadow = true
        self.alphaValue = 0.0
        
        // Position centered along the bottom of the screen
        updatePosition()
    }

    private func updatePosition() {
        if let screen = NSScreen.main {
            let origin = BubblePositioner.origin(screenFrame: screen.visibleFrame, windowSize: self.frame.size)
            self.setFrameOrigin(origin)
        }
    }
    
    func show() {
        self.orderFront(nil)
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.3
            self.animator().alphaValue = 1.0
        }
    }
    
    func hide() {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.3
            self.animator().alphaValue = 0.0
        } completionHandler: {
            self.orderOut(nil)
        }
    }
}
