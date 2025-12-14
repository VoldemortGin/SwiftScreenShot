//
//  HotKeyRecorder.swift
//  SwiftScreenShot
//
//  SwiftUI component for recording keyboard shortcuts
//

import SwiftUI
import Carbon

/// A view for recording and displaying keyboard shortcuts
struct HotKeyRecorder: View {
    let title: String
    @Binding var hotKey: HotKeyConfig
    let otherHotKeys: [HotKeyConfig]
    let onReset: () -> Void

    @State private var isRecording = false
    @State private var errorMessage: String?
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                Spacer()
                Button("重置") {
                    onReset()
                    errorMessage = nil
                }
                .buttonStyle(.link)
                .font(.caption)
            }

            HStack {
                // Hotkey display field
                HStack {
                    if isRecording {
                        Text("请按下新的快捷键...")
                            .foregroundColor(.secondary)
                            .font(.system(size: 13))
                    } else {
                        Text(hotKey.displayString)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.primary)

                        Spacer()

                        Text(hotKey.verboseDisplayString)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isRecording ? Color.accentColor.opacity(0.1) : Color(nsColor: .controlBackgroundColor))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(isRecording ? Color.accentColor : Color.clear, lineWidth: 2)
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    isRecording = true
                    isFocused = true
                }
                .focused($isFocused)
                .onKeyPress { keyPress in
                    if isRecording {
                        handleKeyPress(keyPress)
                        return .handled
                    }
                    return .ignored
                }
            }

            // Error message
            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
            } else {
                Text("点击输入框并按下新的快捷键组合")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
        .onChange(of: isFocused) { _, newValue in
            if !newValue {
                isRecording = false
            }
        }
    }

    private func handleKeyPress(_ keyPress: KeyPress) {
        // Get the key code from the key press
        guard let keyCode = keyPress.keyCode else {
            errorMessage = "无法识别按键"
            return
        }

        // Extract modifiers
        let modifiers = keyPress.carbonModifiers

        // Create new hotkey config
        let newHotKey = HotKeyConfig(keyCode: UInt32(keyCode), modifiers: modifiers)

        // Validate the hotkey
        if let error = validate(newHotKey) {
            errorMessage = error.localizedDescription
            // Don't apply invalid hotkey, keep recording
            return
        }

        // Apply the new hotkey
        hotKey = newHotKey
        isRecording = false
        isFocused = false
        errorMessage = nil
    }

    private func validate(_ config: HotKeyConfig) -> HotKeyValidationError? {
        // Check if modifiers are present
        if config.modifiers == 0 {
            return .noModifiers
        }

        // Check if valid
        if !config.isValid {
            if config.isSystemReserved {
                return .systemReserved
            } else {
                return .invalidKeyCode
            }
        }

        // Check for conflicts with other hotkeys
        for otherHotKey in otherHotKeys {
            if config == otherHotKey {
                // Find which type this conflicts with
                if let conflictType = HotKeyType.allCases.first(where: { $0.defaultConfig == otherHotKey }) {
                    return .conflictWithOther(conflictType)
                }
            }
        }

        return nil
    }
}

// MARK: - KeyPress Extensions

extension KeyPress {
    /// Get the Carbon-compatible key code
    var keyCode: Int? {
        // Map from SwiftUI KeyEquivalent to Carbon key code
        let char = self.characters.first?.lowercased().first

        let keyMap: [Character: Int] = [
            // Letters
            "a": 0, "s": 1, "d": 2, "f": 3, "h": 4, "g": 5, "z": 6, "x": 7, "c": 8, "v": 9,
            "b": 11, "q": 12, "w": 13, "e": 14, "r": 15, "y": 16, "t": 17,
            "o": 31, "u": 32, "i": 34, "p": 35, "l": 37, "j": 38,
            "k": 40, "n": 45, "m": 46,

            // Numbers
            "1": 18, "2": 19, "3": 20, "4": 21, "5": 23, "6": 22, "7": 26, "8": 28, "9": 25, "0": 29,

            // Punctuation
            "=": 24, "-": 27, "]": 30, "[": 33, "'": 39, ";": 41,
            "\\": 42, ",": 43, "/": 44, ".": 47, "`": 50
        ]

        // Check for special keys
        switch self.key {
        case .space:
            return 49
        case .return:
            return 36
        case .tab:
            return 48
        case .delete:
            return 51
        case .escape:
            return 53
        case .leftArrow:
            return 123
        case .rightArrow:
            return 124
        case .downArrow:
            return 125
        case .upArrow:
            return 126
        default:
            if let char = char {
                return keyMap[char]
            }
            return nil
        }
    }

    /// Convert SwiftUI modifiers to Carbon modifiers
    var carbonModifiers: UInt32 {
        var modifiers: UInt32 = 0

        if self.modifiers.contains(.control) {
            modifiers |= UInt32(controlKey)
        }
        if self.modifiers.contains(.option) {
            modifiers |= UInt32(optionKey)
        }
        if self.modifiers.contains(.shift) {
            modifiers |= UInt32(shiftKey)
        }
        if self.modifiers.contains(.command) {
            modifiers |= UInt32(cmdKey)
        }

        return modifiers
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        HotKeyRecorder(
            title: "区域截图",
            hotKey: .constant(.defaultRegionScreenshot),
            otherHotKeys: [.defaultFullScreenshot],
            onReset: {}
        )

        HotKeyRecorder(
            title: "全屏截图",
            hotKey: .constant(.defaultFullScreenshot),
            otherHotKeys: [.defaultRegionScreenshot],
            onReset: {}
        )
    }
    .padding()
    .frame(width: 500)
}
