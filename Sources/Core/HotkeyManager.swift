import AppKit
import Carbon

class HotkeyManager {
    typealias HotkeyAction = () -> Void
    private var actions: [UInt32: HotkeyAction] = [:]
    private var hotkeyRefs: [UInt32: EventHotKeyRef] = [:]
    
    init() {
        setupEventHandler()
    }
    
    func register(modifiers: NSEvent.ModifierFlags, key: KeyCode, action: @escaping HotkeyAction) {
        let carbonModifiers = modifiersToCarbon(modifiers)
        let carbonKeyCode = UInt32(key.rawValue)
        let id = carbonKeyCode + carbonModifiers
        
        actions[id] = action
        
        var hotkeyRef: EventHotKeyRef?
        let hotkeyID = EventHotKeyID(signature: UTGetOSTypeFromString("VTXT" as CFString), id: id)
        
        let status = RegisterEventHotKey(carbonKeyCode, carbonModifiers, hotkeyID, GetApplicationEventTarget(), 0, &hotkeyRef)
        
        if status == noErr, let ref = hotkeyRef {
            hotkeyRefs[id] = ref
        } else {
            print("Failed to register hotkey: \(status)")
        }
    }
    
    private func setupEventHandler() {
        var eventSpec = [
            EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        ]
        
        let handler: EventHandlerUPP = { (_, event, userData) -> OSStatus in
            guard let event = event, let userData = userData else { return OSStatus(eventNotHandledErr) }
            
            var hotkeyID = EventHotKeyID()
            let status = GetEventParameter(event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID), nil, MemoryLayout<EventHotKeyID>.size, nil, &hotkeyID)
            
            if status == noErr {
                let manager = Unmanaged<HotkeyManager>.fromOpaque(userData).takeUnretainedValue()
                manager.actions[hotkeyID.id]?()
                return noErr
            }
            
            return OSStatus(eventNotHandledErr)
        }
        
        InstallEventHandler(GetApplicationEventTarget(), handler, 1, &eventSpec, Unmanaged.passUnretained(self).toOpaque(), nil)
    }
    
    private func modifiersToCarbon(_ modifiers: NSEvent.ModifierFlags) -> UInt32 {
        var result: UInt32 = 0
        if modifiers.contains(.command) { result |= UInt32(cmdKey) }
        if modifiers.contains(.option) { result |= UInt32(optionKey) }
        if modifiers.contains(.shift) { result |= UInt32(shiftKey) }
        if modifiers.contains(.control) { result |= UInt32(controlKey) }
        return result
    }
}

enum KeyCode: CGKeyCode {
    case v = 9
    case space = 49
    // Add more as needed
}

func UTGetOSTypeFromString(_ string: CFString) -> OSType {
    var result: OSType = 0
    if let data = (string as String).data(using: .ascii) {
        for byte in data {
            result = (result << 8) | OSType(byte)
        }
    }
    return result
}
