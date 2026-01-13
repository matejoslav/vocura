import SwiftUI
import AppKit

@main
struct VoiceTextApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Window("Settings", id: "settings") {
            SettingsView()
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
        
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit VoiceText", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        statusItem?.menu = menu
    }
    
    @objc func openSettings() {
        NSApp.activate(ignoringOtherApps: true)
        if let url = URL(string: "voicetext://settings") {
            // Using Workspace to open just in case, but typically we can use NSApp to show a window
        }
        // Simplified open window for this setup:
        let selector = NSSelectorFromString("showSettingsWindow:")
        if NSApp.responds(to: selector) {
            NSApp.perform(selector)
        } else {
            // Fallback for single window apps
            NSApp.windows.first(where: { $0.identifier?.rawValue == "settings" })?.makeKeyAndOrderFront(nil)
        }
    }
    
    func setupHotkeys() {
        // Default hotkey: Command + Shift + Space
        hotkeyManager.register(modifiers: [.command, .shift], key: .space) {
            self.windowManager.toggleRecording()
        }
    }
}
