import Foundation
import Combine
import SwiftUI

class SettingsManager: ObservableObject {
    static let shared = SettingsManager()
    
    @Published var apiKey: String = "" {
        didSet {
            // Avoid infinite loop if value didn't change (though basic string compare is cheap)
            // Save to Keychain
            _ = KeychainHelper.shared.save(apiKey)
        }
    }
    
    @Published var hotkey: KeyShortcut? {
        didSet {
            saveHotkey()
        }
    }
    
    private init() {
        loadSettings()
    }
    
    private func loadSettings() {
        // Load API Key
        if let savedKey = KeychainHelper.shared.load() {
            self.apiKey = savedKey
        }
        
        // Load Hotkey
        if let data = UserDefaults.standard.data(forKey: Constants.UserDefaults.customHotkey),
           let savedHotkey = try? JSONDecoder().decode(KeyShortcut.self, from: data) {
            self.hotkey = savedHotkey
        } else {
            // Default ⇧⌘Space
            self.hotkey = KeyShortcut(keyCode: 49, modifiers: NSEvent.ModifierFlags.command.rawValue | NSEvent.ModifierFlags.shift.rawValue)
        }
    }
    
    private func saveHotkey() {
        if let hotkey = hotkey, let encoded = try? JSONEncoder().encode(hotkey) {
            UserDefaults.standard.set(encoded, forKey: Constants.UserDefaults.customHotkey)
            
            // Notify HotkeyManager to update
            registerHotkey()
        }
    }
    
    func registerHotkey() {
        guard let hotkey = hotkey else { return }
        
        HotkeyManager.shared.unregisterAll()
        HotkeyManager.shared.register(shortcut: hotkey) {
             WindowManager.shared.toggleRecording()
        }
    }
}
