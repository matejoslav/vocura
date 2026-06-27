import SwiftUI
import AppKit
import VocuraKit

@main
struct VocuraApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var settingsManager = SettingsManager.shared
    
    var body: some Scene {
        Window("Settings", id: "settings") {
            SettingsView()
                .environmentObject(settingsManager)
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBar()

        // Ensure the app doesn't show in the dock
        NSApp.setActivationPolicy(.accessory)

        // Prompt for accessibility permissions once at startup
        requestAccessibilityPermissions()

        // Connect Core to UI. Settings load + hotkey registration already
        // happened in SettingsManager.init; the registered closure reads
        // hotkeyAction lazily, so setting it here is sufficient.
        SettingsManager.shared.hotkeyAction = {
            WindowManager.shared.toggleRecording()
        }
    }
    
    private func requestAccessibilityPermissions() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        AXIsProcessTrustedWithOptions(options as CFDictionary)
    }
    
    func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem?.button {
            if let image = NSImage(named: NSImage.Name("AppIcon")) {
                image.size = NSSize(width: 18, height: 18)
                image.isTemplate = true
                button.image = image
            } else if let resourceURL = Bundle.main.url(forResource: "AppIcon", withExtension: "png"),
                      let image = NSImage(contentsOf: resourceURL) {
                image.size = NSSize(width: 18, height: 18)
                image.isTemplate = true
                button.image = image
            } else {
                 button.image = NSImage(systemSymbolName: "waveform.circle", accessibilityDescription: Constants.App.name)
            }
        }
        
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit \(Constants.App.name)", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        statusItem?.menu = menu
    }
    
    @objc func openSettings() {
        NSApp.activate(ignoringOtherApps: true)
        
        let selector = NSSelectorFromString("showSettingsWindow:")
        if NSApp.responds(to: selector) {
            NSApp.perform(selector)
        } else {
            // Fallback for single window apps
            NSApp.windows.first(where: { $0.identifier?.rawValue == "settings" })?.makeKeyAndOrderFront(nil)
        }
    }
}
