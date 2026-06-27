import Foundation

public enum Constants {
    public enum UserDefaults {
        public static let customHotkey = "customHotkey"
    }
    
    public enum Keychain {
        // service name usually matches bundle identifier or app name
        public static let serviceName = "com.vocura.app" 
        public static let apiKeyAccount = "deepgramApiKey"
    }
    
    public enum App {
        public static let name = "Vocura"
        public static let defaultHotkeyDisplay = "⇧⌘Space"
    }

    public enum Environment {
        /// True when the process is hosting an XCTest run, used to skip real I/O at app launch.
        public static var isRunningTests: Bool {
            ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
        }
    }
}

