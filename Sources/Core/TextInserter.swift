import AppKit
import Accessibility

class TextInserter {
    func insert(_ text: String) {
        print("TextInserter: Attempting to insert: \(text)")
        
        // Check if we have accessibility permissions SILENTLY
        let isTrusted = AXIsProcessTrusted()
        print("TextInserter: Accessibility trusted: \(isTrusted)")
        
        if isTrusted {
            // Priority 1: Use Accessibility API to replace selection (most robust)
            if insertUsingSelectedTextAttribute(text) {
                print("TextInserter: Successfully inserted using kAXSelectedTextAttribute")
                return
            }
            
            // Priority 2: Fallback to keyboard events (Cmd+V)
            print("TextInserter: Falling back to keyboard events")
            _ = insertViaKeyboardEvents(text)
        } else {
            print("TextInserter: Accessibility permissions not granted. Falling back to clipboard only.")
            // Fallback to clipboard only
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.setString(text, forType: .string)
        }
    }
    
    private func insertUsingSelectedTextAttribute(_ text: String) -> Bool {
        let systemWideElement = AXUIElementCreateSystemWide()
        
        var focusedElement: AnyObject?
        let result = AXUIElementCopyAttributeValue(systemWideElement, kAXFocusedUIElementAttribute as CFString, &focusedElement)
        
        guard result == .success, let element = focusedElement as! AXUIElement? else {
            print("TextInserter: Could not find focused UI element")
            return false
        }
        
        // Setting kAXSelectedTextAttribute replaces the current selection with the new text.
        // If the selection is just a cursor, it's an insertion.
        let setStatus = AXUIElementSetAttributeValue(element, kAXSelectedTextAttribute as CFString, text as CFString)
        return setStatus == .success
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
