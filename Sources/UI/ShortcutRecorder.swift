import SwiftUI
import Carbon

struct ShortcutRecorder: View {
    @Binding var shortcut: KeyShortcut?
    @State private var isRecording = false
    @State private var monitor: Any?
    
    // Modifier key codes to ignore when triggered alone
    private let modifierKeyCodes: Set<UInt16> = [
        55, // Command
        56, // Shift
        58, // Option
        59, // Control
        60, // Right Shift
        61, // Right Option
        62, // Right Control
        63  // Function
    ]
    
    var body: some View {
        Button(action: toggleRecording) {
            HStack {
                if isRecording {
                    Text("Press new shortcut...")
                        .foregroundColor(.secondary)
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                } else if let shortcut = shortcut {
                    Text(shortcut.description)
                } else {
                    Text("Click to record")
                        .foregroundColor(.secondary)
                }
            }
            .padding(4)
            .background(isRecording ? Color.accentColor.opacity(0.1) : Color.clear)
            .cornerRadius(4)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(isRecording ? Color.accentColor : Color.secondary.opacity(0.5), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .onDisappear {
            stopRecording()
        }
    }
    
    private func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }
    
    private func startRecording() {
        isRecording = true
        monitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { event in
            // Ignore just modifier key presses
            if self.modifierKeyCodes.contains(event.keyCode) {
                return event
            }
            
            // Create shortcut
            let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask).rawValue
            let newShortcut = KeyShortcut(keyCode: event.keyCode, modifiers: modifiers)
            
            DispatchQueue.main.async {
                self.shortcut = newShortcut
                self.stopRecording()
            }
            
            return nil // Consume event
        }
    }
    
    private func stopRecording() {
        isRecording = false
        if let monitor = monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
    }
}
