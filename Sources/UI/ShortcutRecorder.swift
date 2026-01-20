import SwiftUI
import Carbon

struct ShortcutRecorder: View {
    @Binding var shortcut: KeyShortcut?
    @State private var isRecording = false
    @State private var monitor: Any?
    
    var body: some View {
        Button(action: {
            if isRecording {
                stopRecording()
            } else {
                startRecording()
            }
        }) {
            HStack {
                if isRecording {
                    Text("Press new shortcut...")
                        .foregroundColor(.secondary)
                } else if let shortcut = shortcut {
                    Text(shortcut.description)
                } else {
                    Text("Click to record")
                        .foregroundColor(.secondary)
                }
                
                if isRecording {
                    Image(systemName: "xmark.circle.fill")
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
    
    private func startRecording() {
        isRecording = true
        monitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { event in
            // Ignore just modifier key presses
            if event.keyCode == 55 || event.keyCode == 56 || event.keyCode == 58 || 
               event.keyCode == 59 || event.keyCode == 60 || event.keyCode == 61 || 
               event.keyCode == 62 || event.keyCode == 63 { 
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
