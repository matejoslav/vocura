import AppKit
import Accessibility

public class TextInserter {
    public init() {}
    
    public func insert(_ text: String) {
        print("TextInserter: Attempting to insert: \(text)")
        
        // Check if we have accessibility permissions SILENTLY
        let isTrusted = AXIsProcessTrusted()
        print("TextInserter: Accessibility trusted: \(isTrusted)")
        
        if isTrusted {
            print("TextInserter: Inserting via keyboard events")
            _ = insertViaKeyboardEvents(text)
        } else {
            print("TextInserter: Accessibility permissions not granted. Falling back to clipboard only.")
            // Fallback to clipboard only
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.setString(text, forType: .string)
        }
    }

    private func insertViaKeyboardEvents(_ text: String) -> Bool {
        let source = CGEventSource(stateID: .combinedSessionState)
        
        let pasteboard = NSPasteboard.general
        let oldContent = pasteboard.string(forType: .string)
        
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        
        let vKey: CGKeyCode = 9
        
        // Command + V Down
        let cmdVDown = CGEvent(keyboardEventSource: source, virtualKey: vKey, keyDown: true)
        cmdVDown?.flags = .maskCommand
        
        // Command + V Up
        let cmdVUp = CGEvent(keyboardEventSource: source, virtualKey: vKey, keyDown: false)
        cmdVUp?.flags = .maskCommand
        
        // Post events
        cmdVDown?.post(tap: .cghidEventTap)
        cmdVUp?.post(tap: .cghidEventTap)
        
        // Restore old clipboard content after a longer delay to ensure paste finished
        if let oldContent = oldContent {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                let pb = NSPasteboard.general
                pb.clearContents()
                pb.setString(oldContent, forType: .string)
            }
        }
        
        return true
    }
}
