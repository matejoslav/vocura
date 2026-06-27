import AppKit
import Carbon

class HotkeyManager: HotkeyManaging {
    static let shared = HotkeyManager()
    
    typealias HotkeyAction = () -> Void
    private var actions: [UInt32: HotkeyAction] = [:]
    private var hotkeyRefs: [UInt32: EventHotKeyRef] = [:]
    
    private init() {
        setupEventHandler()
    }
    
    func register(shortcut: KeyShortcut, action: @escaping HotkeyAction) {
        let carbonModifiers = modifiersToCarbon(NSEvent.ModifierFlags(rawValue: shortcut.modifiers))
        let carbonKeyCode = UInt32(shortcut.keyCode)
        let id = carbonKeyCode + carbonModifiers
        
        // Remove existing if present (simple replacement strategy)
        if hotkeyRefs[id] != nil {
            unregister(id: id)
        }
        
        actions[id] = action
        
        var hotkeyRef: EventHotKeyRef?
        let signature = UTGetOSTypeFromString("VTXT" as CFString)
        let hotkeyID = EventHotKeyID(signature: signature, id: id)
        
        let status = RegisterEventHotKey(carbonKeyCode, carbonModifiers, hotkeyID, GetApplicationEventTarget(), 0, &hotkeyRef)
        
        if status == noErr, let ref = hotkeyRef {
            hotkeyRefs[id] = ref
        } else {
            print("Failed to register hotkey: \(status)")
        }
    }
    
    func unregisterAll() {
        for (id, _) in hotkeyRefs {
            unregister(id: id)
        }
    }
    
    private func unregister(id: UInt32) {
        if let ref = hotkeyRefs[id] {
            UnregisterEventHotKey(ref)
            hotkeyRefs.removeValue(forKey: id)
            actions.removeValue(forKey: id)
        }
    }
    
    private func setupEventHandler() {
        var eventSpec = [
            EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        ]
        
        let handler: EventHandlerUPP = { (_, event, _) -> OSStatus in
            guard let event = event else { return OSStatus(eventNotHandledErr) }
            
            var hotkeyID = EventHotKeyID()
            let status = GetEventParameter(
                event,
                EventParamName(kEventParamDirectObject),
                EventParamType(typeEventHotKeyID),
                nil,
                MemoryLayout<EventHotKeyID>.size,
                nil,
                &hotkeyID
            )
            
            if status == noErr {
                HotkeyManager.shared.actions[hotkeyID.id]?()
                return noErr
            }
            
            return OSStatus(eventNotHandledErr)
        }
        
        InstallEventHandler(GetApplicationEventTarget(), handler, 1, &eventSpec, nil, nil)
    }
    
    private func modifiersToCarbon(_ modifiers: NSEvent.ModifierFlags) -> UInt32 {
        var result: UInt32 = 0
        if modifiers.contains(.command) { result |= UInt32(cmdKey) }
        if modifiers.contains(.option) { result |= UInt32(optionKey) }
        if modifiers.contains(.shift) { result |= UInt32(shiftKey) }
        if modifiers.contains(.control) { result |= UInt32(controlKey) }
        return result
    }
    
    private func UTGetOSTypeFromString(_ string: CFString) -> OSType {
        var result: OSType = 0
        if let data = (string as String).data(using: .ascii) {
            for byte in data {
                result = (result << 8) | OSType(byte)
            }
        }
        return result
    }
}
