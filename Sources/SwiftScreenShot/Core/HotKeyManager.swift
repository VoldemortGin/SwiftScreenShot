//
//  HotKeyManager.swift
//  SwiftScreenShot
//
//  Global hotkey manager using Carbon Event Manager
//

import Carbon
import Cocoa

/// Represents a registered hotkey
struct HotKey {
    let id: UInt32
    let key: UInt32
    let modifiers: UInt32
    let action: () -> Void
    var eventHotKeyRef: EventHotKeyRef?
}

class HotKeyManager {
    private var hotKeys: [UInt32: HotKey] = [:]
    private var eventHandler: EventHandlerRef?
    private var nextHotKeyID: UInt32 = 1
    private var registrationFailureHandler: ((HotKeyConfig, OSStatus) -> Void)?

    init() {
        setupEventHandler()
    }

    private func setupEventHandler() {
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        // Install event handler
        InstallEventHandler(
            GetApplicationEventTarget(),
            { (nextHandler, theEvent, userData) -> OSStatus in
                guard let userData = userData else { return noErr }

                let manager = Unmanaged<HotKeyManager>
                    .fromOpaque(userData)
                    .takeUnretainedValue()

                // Get hotkey ID
                var hotKeyID = EventHotKeyID()
                GetEventParameter(
                    theEvent,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hotKeyID
                )

                // Execute corresponding action
                if let hotKey = manager.hotKeys[hotKeyID.id] {
                    hotKey.action()
                }

                return noErr
            },
            1,
            &eventType,
            Unmanaged.passUnretained(self).toOpaque(),
            &eventHandler
        )
    }

    /// Set the registration failure handler
    func setRegistrationFailureHandler(_ handler: @escaping (HotKeyConfig, OSStatus) -> Void) {
        self.registrationFailureHandler = handler
    }

    /// Register a new hotkey
    /// - Parameters:
    ///   - key: Virtual key code (e.g., 0 for 'A', 6 for '3')
    ///   - modifiers: Modifier flags (e.g., cmdKey, controlKey, shiftKey)
    ///   - action: Closure to execute when hotkey is pressed
    /// - Returns: Hotkey ID for later unregistration, or nil if registration failed
    @discardableResult
    func register(key: UInt32, modifiers: UInt32, action: @escaping () -> Void) -> UInt32? {
        let hotKeyID = nextHotKeyID
        nextHotKeyID += 1

        let hotKeyIDStruct = EventHotKeyID(
            signature: 0x53535353, // 'SSSS' for SwiftScreenShot
            id: hotKeyID
        )

        var hotKeyRef: EventHotKeyRef?
        let status = RegisterEventHotKey(
            key,
            modifiers,
            hotKeyIDStruct,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )

        if status == noErr {
            var hotKey = HotKey(
                id: hotKeyID,
                key: key,
                modifiers: modifiers,
                action: action
            )
            hotKey.eventHotKeyRef = hotKeyRef
            hotKeys[hotKeyID] = hotKey
            AppLogger.shared.debug("Registered hotkey \(hotKeyID): key=\(key), modifiers=\(modifiers)", category: .hotkey)
            return hotKeyID
        } else {
            AppLogger.shared.error("Failed to register hotkey: status=\(status)", category: .hotkey)
            let config = HotKeyConfig(keyCode: key, modifiers: modifiers)
            registrationFailureHandler?(config, status)
            return nil
        }
    }

    /// Register a hotkey using HotKeyConfig
    /// - Parameters:
    ///   - config: The hotkey configuration
    ///   - action: Closure to execute when hotkey is pressed
    /// - Returns: Hotkey ID for later unregistration, or nil if registration failed
    @discardableResult
    func register(config: HotKeyConfig, action: @escaping () -> Void) -> UInt32? {
        return register(key: config.keyCode, modifiers: config.modifiers, action: action)
    }

    /// Unregister a specific hotkey
    func unregister(id: UInt32) {
        if let hotKey = hotKeys[id] {
            if let ref = hotKey.eventHotKeyRef {
                UnregisterEventHotKey(ref)
            }
            hotKeys.removeValue(forKey: id)
            AppLogger.shared.debug("Unregistered hotkey \(id)", category: .hotkey)
        }
    }

    /// Unregister all hotkeys
    func unregisterAll() {
        // Unregister each hotkey properly
        for (_, hotKey) in hotKeys {
            if let ref = hotKey.eventHotKeyRef {
                UnregisterEventHotKey(ref)
            }
        }
        hotKeys.removeAll()
    }

    deinit {
        unregisterAll()
        if let eventHandler = eventHandler {
            RemoveEventHandler(eventHandler)
            self.eventHandler = nil
        }
    }
}
