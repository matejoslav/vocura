import Foundation

enum Constants {
    enum UserDefaults {
        static let customHotkey = "customHotkey"
    }
    
    enum Keychain {
        // service name usually matches bundle identifier or app name
        static let serviceName = "com.vocura.app" 
        static let apiKeyAccount = "deepgramApiKey"
    }
    
    enum App {
        static let name = "Vocura"
        static let defaultHotkeyDisplay = "⇧⌘Space"
    }
}
