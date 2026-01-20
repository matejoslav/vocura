import SwiftUI

struct SettingsView: View {
    @State private var apiKey: String = ""
    @State private var hotkey: KeyShortcut?
    @State private var showingSaveSuccess = false
    
    var body: some View {
        Form {
            Section {
                SecureField("Deepgram API Key", text: $apiKey)
                    .textFieldStyle(.roundedBorder)
                
                Text("Get your key at [console.deepgram.com](https://console.deepgram.com)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } header: {
                Text("STT Configuration")
            }
            
            Section {
                HStack {
                    Text("Toggle Hotkey:")
                    Spacer()
                    ShortcutRecorder(shortcut: $hotkey)
                }
            } header: {
                Text("General")
            } footer: {
                if showingSaveSuccess {
                    Text("Settings saved successfully!")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
            
            HStack {
                Spacer()
                Button("Save Settings") {
                    saveSettings()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(width: 400, height: 250)
        .onAppear {
            loadSettings()
        }
    }
    
    private func loadSettings() {
        if let savedKey = KeychainHelper.shared.load() {
            apiKey = savedKey
        }
        
        if let data = UserDefaults.standard.data(forKey: "customHotkey"),
           let savedHotkey = try? JSONDecoder().decode(KeyShortcut.self, from: data) {
            hotkey = savedHotkey
        } else {
            // Default ⇧⌘Space
            hotkey = KeyShortcut(keyCode: 49, modifiers: NSEvent.ModifierFlags.command.rawValue | NSEvent.ModifierFlags.shift.rawValue)
        }
    }
    
    private func saveSettings() {
        var success = true
        
        if !KeychainHelper.shared.save(apiKey) {
            success = false
        }
        
        if let hotkey = hotkey, let encoded = try? JSONEncoder().encode(hotkey) {
            UserDefaults.standard.set(encoded, forKey: "customHotkey")
            
            // Re-register hotkey
            HotkeyManager.shared.unregisterAll()
            HotkeyManager.shared.register(shortcut: hotkey) {
                WindowManager.shared.toggleRecording()
            }
        }
        
        if success {
            showingSaveSuccess = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                showingSaveSuccess = false
            }
        }
    }
}
