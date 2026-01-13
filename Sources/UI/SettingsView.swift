import SwiftUI

struct SettingsView: View {
    @State private var apiKey: String = ""
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
        .frame(width: 400, height: 200)
        .onAppear {
            loadSettings()
        }
    }
    
    private func loadSettings() {
        if let savedKey = KeychainHelper.shared.load() {
            apiKey = savedKey
        }
    }
    
    private func saveSettings() {
        if KeychainHelper.shared.save(apiKey) {
            showingSaveSuccess = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                showingSaveSuccess = false
            }
        }
    }
}
