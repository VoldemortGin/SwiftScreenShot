//
//  HotKeyConfig.swift
//  SwiftScreenShot
//
//  Hotkey configuration model for storing and managing keyboard shortcuts
//

import Foundation
import Carbon

/// Represents a keyboard shortcut configuration
struct HotKeyConfig: Codable, Equatable {
    let keyCode: UInt32
    let modifiers: UInt32

    /// Default hotkey for region screenshot: Ctrl+Cmd+A
    static let defaultRegionScreenshot = HotKeyConfig(
        keyCode: 0,  // 'A' key
        modifiers: UInt32(cmdKey | controlKey)
    )

    /// Default hotkey for fullscreen screenshot: Shift+Cmd+3
    static let defaultFullScreenshot = HotKeyConfig(
        keyCode: 20,  // '3' key
        modifiers: UInt32(cmdKey | shiftKey)
    )

    /// Default hotkey for window screenshot: Ctrl+Cmd+W
    static let defaultWindowScreenshot = HotKeyConfig(
        keyCode: 13,  // 'W' key
        modifiers: UInt32(cmdKey | controlKey)
    )

    /// Create a hotkey configuration
    init(keyCode: UInt32, modifiers: UInt32) {
        self.keyCode = keyCode
        self.modifiers = modifiers
    }

    /// Display string for the hotkey (e.g., "⌃⌘A")
    var displayString: String {
        var parts: [String] = []

        // Add modifiers in macOS standard order
        if modifiers & UInt32(controlKey) != 0 {
            parts.append("⌃")
        }
        if modifiers & UInt32(optionKey) != 0 {
            parts.append("⌥")
        }
        if modifiers & UInt32(shiftKey) != 0 {
            parts.append("⇧")
        }
        if modifiers & UInt32(cmdKey) != 0 {
            parts.append("⌘")
        }

        // Add key character
        if let keyChar = keyCodeToCharacter(keyCode) {
            parts.append(keyChar)
        } else {
            parts.append("?")
        }

        return parts.joined()
    }

    /// Verbose display string (e.g., "Control+Command+A")
    var verboseDisplayString: String {
        var parts: [String] = []

        if modifiers & UInt32(controlKey) != 0 {
            parts.append("Control")
        }
        if modifiers & UInt32(optionKey) != 0 {
            parts.append("Option")
        }
        if modifiers & UInt32(shiftKey) != 0 {
            parts.append("Shift")
        }
        if modifiers & UInt32(cmdKey) != 0 {
            parts.append("Command")
        }

        if let keyChar = keyCodeToCharacter(keyCode) {
            parts.append(keyChar)
        } else {
            parts.append("Unknown")
        }

        return parts.joined(separator: "+")
    }

    /// Validate the hotkey configuration
    var isValid: Bool {
        // Must have at least one modifier
        guard modifiers != 0 else { return false }

        // Must have a valid key code
        guard keyCodeToCharacter(keyCode) != nil else { return false }

        // Check for reserved system shortcuts
        if isSystemReserved {
            return false
        }

        return true
    }

    /// Check if this hotkey is reserved by the system
    var isSystemReserved: Bool {
        // Common system shortcuts to avoid
        let reserved: [(UInt32, UInt32)] = [
            (48, UInt32(cmdKey)),                    // Cmd+Tab (app switcher)
            (53, UInt32(cmdKey)),                    // Cmd+Esc
            (12, UInt32(cmdKey)),                    // Cmd+Q (quit)
            (31, UInt32(cmdKey)),                    // Cmd+O (open)
            (45, UInt32(cmdKey)),                    // Cmd+N (new)
            (1, UInt32(cmdKey)),                     // Cmd+S (save)
            (15, UInt32(cmdKey)),                    // Cmd+R (reload)
            (17, UInt32(cmdKey)),                    // Cmd+T (new tab)
            (13, UInt32(cmdKey)),                    // Cmd+W (close window)
            (48, UInt32(cmdKey | shiftKey)),         // Cmd+Shift+Tab
            (53, UInt32(cmdKey | optionKey)),        // Cmd+Option+Esc (force quit)
        ]

        for (keyCode, mods) in reserved {
            if self.keyCode == keyCode && self.modifiers == mods {
                return true
            }
        }

        return false
    }

    /// Convert key code to character representation
    private func keyCodeToCharacter(_ keyCode: UInt32) -> String? {
        // Map of common key codes to their character representations
        let keyMap: [UInt32: String] = [
            // Letters
            0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G", 6: "Z", 7: "X", 8: "C", 9: "V",
            11: "B", 12: "Q", 13: "W", 14: "E", 15: "R", 16: "Y", 17: "T",
            31: "O", 32: "U", 34: "I", 35: "P", 37: "L", 38: "J",
            40: "K", 45: "N", 46: "M",

            // Numbers
            18: "1", 19: "2", 20: "3", 21: "4", 23: "5", 22: "6", 26: "7", 28: "8", 25: "9", 29: "0",

            // Function keys
            122: "F1", 120: "F2", 99: "F3", 118: "F4", 96: "F5", 97: "F6",
            98: "F7", 100: "F8", 101: "F9", 109: "F10", 103: "F11", 111: "F12",

            // Special keys
            36: "↩", 48: "⇥", 49: "Space", 51: "⌫",
            53: "⎋", 123: "←", 124: "→", 125: "↓", 126: "↑",

            // Punctuation
            24: "=", 27: "-", 30: "]", 33: "[", 39: "'", 41: ";",
            42: "\\", 43: ",", 44: "/", 47: ".", 50: "`"
        ]

        return keyMap[keyCode]
    }
}

/// Hotkey type enumeration
enum HotKeyType: String, CaseIterable {
    case regionScreenshot = "regionScreenshot"
    case fullScreenshot = "fullScreenshot"
    case windowScreenshot = "windowScreenshot"

    var displayName: String {
        switch self {
        case .regionScreenshot:
            return "区域截图"
        case .fullScreenshot:
            return "全屏截图"
        case .windowScreenshot:
            return "窗口截图"
        }
    }

    var defaultConfig: HotKeyConfig {
        switch self {
        case .regionScreenshot:
            return .defaultRegionScreenshot
        case .fullScreenshot:
            return .defaultFullScreenshot
        case .windowScreenshot:
            return .defaultWindowScreenshot
        }
    }
}

/// Hotkey validation result
enum HotKeyValidationError: LocalizedError {
    case noModifiers
    case invalidKeyCode
    case systemReserved
    case conflictWithOther(HotKeyType)

    var errorDescription: String? {
        switch self {
        case .noModifiers:
            return "快捷键必须包含至少一个修饰键(⌃⌥⇧⌘)"
        case .invalidKeyCode:
            return "无效的按键组合"
        case .systemReserved:
            return "此快捷键已被系统保留"
        case .conflictWithOther(let type):
            return "与\(type.displayName)的快捷键冲突"
        }
    }
}
