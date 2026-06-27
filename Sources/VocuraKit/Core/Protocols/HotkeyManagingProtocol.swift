import Foundation

/// Protocol abstraction for global hotkey registration, enabling dependency injection and testing.
protocol HotkeyManaging {
    func register(shortcut: KeyShortcut, action: @escaping () -> Void)
    func unregisterAll()
}
