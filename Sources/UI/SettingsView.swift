import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @State private var showingSaveSuccess = false
    
    var body: some View {
        Form {
            Section {
                SecureField("Deepgram API Key", text: $settingsManager.apiKey)
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
                    ShortcutRecorder(shortcut: $settingsManager.hotkey)
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
                    // Settings are saved automatically via bindings in SettingsManager
                    // But we can simulate a "save" action for user feedback
                    showingSaveSuccess = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        showingSaveSuccess = false
                    }
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(width: 400, height: 250)
    }
}
