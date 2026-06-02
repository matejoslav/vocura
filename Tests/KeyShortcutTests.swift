import XCTest
import AppKit
@testable import Vocura

/// Tests for KeyShortcut struct
final class KeyShortcutTests: XCTestCase {
    
    // MARK: - Encoding/Decoding Tests
    
    func testKeyShortcutEncodesToJSON() throws {
        let shortcut = KeyShortcut(keyCode: 49, modifiers: NSEvent.ModifierFlags.command.rawValue)
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(shortcut)
        
        XCTAssertNotNil(data)
        XCTAssertFalse(data.isEmpty)
    }
    
    func testKeyShortcutDecodesFromJSON() throws {
        let originalShortcut = KeyShortcut(
            keyCode: 49,
            modifiers: NSEvent.ModifierFlags.command.rawValue | NSEvent.ModifierFlags.shift.rawValue
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(originalShortcut)
        
        let decoder = JSONDecoder()
        let decodedShortcut = try decoder.decode(KeyShortcut.self, from: data)
        
        XCTAssertEqual(originalShortcut, decodedShortcut)
        XCTAssertEqual(originalShortcut.keyCode, decodedShortcut.keyCode)
        XCTAssertEqual(originalShortcut.modifiers, decodedShortcut.modifiers)
    }
    
    func testKeyShortcutRoundTrip() throws {
        // Test multiple combinations
        let shortcuts = [
            KeyShortcut(keyCode: 49, modifiers: NSEvent.ModifierFlags.command.rawValue),
            KeyShortcut(keyCode: 36, modifiers: NSEvent.ModifierFlags.control.rawValue | NSEvent.ModifierFlags.option.rawValue),
            KeyShortcut(keyCode: 0, modifiers: NSEvent.ModifierFlags.shift.rawValue)
        ]
        
        for original in shortcuts {
            let data = try JSONEncoder().encode(original)
            let decoded = try JSONDecoder().decode(KeyShortcut.self, from: data)
            XCTAssertEqual(original, decoded, "Round trip failed for shortcut with keyCode \(original.keyCode)")
        }
    }
    
    // MARK: - Equality Tests
    
    func testKeyShortcutEquality() {
        let shortcut1 = KeyShortcut(keyCode: 49, modifiers: NSEvent.ModifierFlags.command.rawValue)
        let shortcut2 = KeyShortcut(keyCode: 49, modifiers: NSEvent.ModifierFlags.command.rawValue)
        let shortcut3 = KeyShortcut(keyCode: 50, modifiers: NSEvent.ModifierFlags.command.rawValue)
        
        XCTAssertEqual(shortcut1, shortcut2)
        XCTAssertNotEqual(shortcut1, shortcut3)
    }
    
    func testKeyShortcutInequalityDifferentModifiers() {
        let shortcut1 = KeyShortcut(keyCode: 49, modifiers: NSEvent.ModifierFlags.command.rawValue)
        let shortcut2 = KeyShortcut(keyCode: 49, modifiers: NSEvent.ModifierFlags.shift.rawValue)
        
        XCTAssertNotEqual(shortcut1, shortcut2)
    }
    
    // MARK: - Description Tests (basic, without keyboard layout dependency)
    
    func testDescriptionIncludesModifierSymbols() {
        // Test command modifier
        let cmdShortcut = KeyShortcut(keyCode: 49, modifiers: NSEvent.ModifierFlags.command.rawValue)
        XCTAssertTrue(cmdShortcut.description.contains("⌘"), "Description should contain command symbol")
        
        // Test shift modifier
        let shiftShortcut = KeyShortcut(keyCode: 49, modifiers: NSEvent.ModifierFlags.shift.rawValue)
        XCTAssertTrue(shiftShortcut.description.contains("⇧"), "Description should contain shift symbol")
        
        // Test control modifier
        let ctrlShortcut = KeyShortcut(keyCode: 49, modifiers: NSEvent.ModifierFlags.control.rawValue)
        XCTAssertTrue(ctrlShortcut.description.contains("⌃"), "Description should contain control symbol")
        
        // Test option modifier
        let optShortcut = KeyShortcut(keyCode: 49, modifiers: NSEvent.ModifierFlags.option.rawValue)
        XCTAssertTrue(optShortcut.description.contains("⌥"), "Description should contain option symbol")
    }
    
    func testDescriptionIncludesMultipleModifiers() {
        let shortcut = KeyShortcut(
            keyCode: 49,
            modifiers: NSEvent.ModifierFlags.command.rawValue | NSEvent.ModifierFlags.shift.rawValue
        )
        
        XCTAssertTrue(shortcut.description.contains("⇧"), "Description should contain shift symbol")
        XCTAssertTrue(shortcut.description.contains("⌘"), "Description should contain command symbol")
    }
    
    func testDescriptionForSpaceKey() {
        let shortcut = KeyShortcut(keyCode: 49, modifiers: NSEvent.ModifierFlags.command.rawValue)
        // Key code 49 is Space
        XCTAssertTrue(shortcut.description.contains("Space"), "Description should contain 'Space' for keyCode 49")
    }
}
