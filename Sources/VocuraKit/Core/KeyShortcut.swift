import SwiftUI
import Carbon

public struct KeyShortcut: Codable, Equatable {
    public var keyCode: UInt16
    public var modifiers: UInt
    
    public init(keyCode: UInt16, modifiers: UInt) {
        self.keyCode = keyCode
        self.modifiers = modifiers
    }
    
    public var description: String {
        var str = ""
        
        let modFlags = NSEvent.ModifierFlags(rawValue: modifiers)
        if modFlags.contains(.control) { str += "⌃" }
        if modFlags.contains(.option) { str += "⌥" }
        if modFlags.contains(.shift) { str += "⇧" }
        if modFlags.contains(.command) { str += "⌘" }
        
        str += keyCodeToString(keyCode)
        return str
    }
    
    private func keyCodeToString(_ code: UInt16) -> String {
        switch Int(code) {
        case kVK_Space: return "Space"
        case kVK_Return: return "↩"
        case kVK_Tab: return "⇥"
        case kVK_Delete: return "⌫"
        case kVK_Escape: return "⎋"
        case kVK_RightArrow: return "→"
        case kVK_LeftArrow: return "←"
        case kVK_UpArrow: return "↑"
        case kVK_DownArrow: return "↓"
        default:
             // Try to convert to character
            let source = TISCopyCurrentKeyboardInputSource().takeRetainedValue()
            let layoutData = TISGetInputSourceProperty(source, kTISPropertyUnicodeKeyLayoutData)
            
            if let layoutData = layoutData {
                let dataRef = unsafeBitCast(layoutData, to: CFData.self)
                let keyLayout = unsafeBitCast(CFDataGetBytePtr(dataRef), to: UnsafePointer<UCKeyboardLayout>.self)
                
                var deadKeyState: UInt32 = 0
                var actualStringLength = 0
                var unicodeString = [UniChar](repeating: 0, count: 4)
                
                let status = UCKeyTranslate(
                    keyLayout,
                    code,
                    UInt16(kUCKeyActionDisplay),
                    0, // No modifiers for display name
                    UInt32(LMGetKbdType()),
                    OptionBits(kUCKeyTranslateNoDeadKeysBit),
                    &deadKeyState,
                    4,
                    &actualStringLength,
                    &unicodeString
                )
                
                if status == noErr && actualStringLength > 0 {
                    return String(utf16CodeUnits: &unicodeString, count: actualStringLength).uppercased()
                }
            }
            return "?"
        }
    }
}

