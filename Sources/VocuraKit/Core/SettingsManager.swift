import Foundation
import Combine
import SwiftUI

public class SettingsManager: ObservableObject {
    public static let shared = SettingsManager()

    private let keychainService: KeychainServiceProtocol
    private let hotkeyManager: HotkeyManaging

    /// Callback to be invoked when hotkey is triggered. Set by the UI layer.
    public var hotkeyAction: (() -> Void)?

    @Published public var apiKey: String = "" {
        didSet {
            // Avoid infinite loop if value didn't change (though basic string compare is cheap)
            // Save to Keychain
            _ = keychainService.save(apiKey)
        }
    }
    
    @Published public var hotkey: KeyShortcut? {
        didSet {
            saveHotkey()
        }
    }
    
    init(
        keychainService: KeychainServiceProtocol = KeychainHelper.shared,
        hotkeyManager: HotkeyManaging = HotkeyManager.shared
    ) {
        self.keychainService = keychainService
        self.hotkeyManager = hotkeyManager
    }

    /// Loads persisted settings (Keychain + hotkey) and registers the hotkey.
    /// Kept out of `init` so constructing the singleton performs no I/O.
    public func bootstrap() {
        loadSettings()
    }

    private func loadSettings() {
        // Load API Key
        if let savedKey = keychainService.load() {
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
    
    public func registerHotkey() {
        guard let hotkey = hotkey else { return }
        
        hotkeyManager.unregisterAll()
        hotkeyManager.register(shortcut: hotkey) { [weak self] in
            self?.hotkeyAction?()
        }
    }
}

