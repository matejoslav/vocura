import SwiftUI
import AppKit

@main
struct VoiceTextApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    let windowManager = WindowManager.shared
    let hotkeyManager = HotkeyManager()
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBar()
        setupHotkeys()
        
        // Ensure the app doesn't show in the dock
        NSApp.setActivationPolicy(.accessory)
        
        // Prompt for accessibility permissions once at startup
        requestAccessibilityPermissions()
    }
    
    private func requestAccessibilityPermissions() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        AXIsProcessTrustedWithOptions(options as CFDictionary)
    }
    
    func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "waveform.circle", accessibilityDescription: "Voice Text")
        }
    }
    
    func setupHotkeys() {
        // Default hotkey: Command + Shift + Space
        hotkeyManager.register(modifiers: [.command, .shift], key: .space) {
            self.windowManager.toggleRecording()
        }
    }
}
