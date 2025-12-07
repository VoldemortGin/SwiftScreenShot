//
//  HotKeyManager.swift
//  SwiftScreenShot
//
//  Global hotkey manager using Carbon Event Manager
//

import Carbon
import Cocoa

class HotKeyManager {
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    var onHotKeyPressed: (() -> Void)?

    func register(key: UInt32, modifiers: UInt32) {
        // Register hotkey: Ctrl+Cmd+A
        var hotKeyID = EventHotKeyID(signature: 0x53535353, id: 1) // 'SSSS' for SwiftScreenShot
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                       eventKind: UInt32(kEventHotKeyPressed))

        // Install event handler
        InstallEventHandler(GetApplicationEventTarget(),
                            { (nextHandler, theEvent, userData) -> OSStatus in
            let manager = Unmanaged<HotKeyManager>
                .fromOpaque(userData!)
                .takeUnretainedValue()
            manager.onHotKeyPressed?()
            return noErr
        }, 1, &eventType,
        Unmanaged.passUnretained(self).toOpaque(),
        &eventHandler)

        // Register hotkey (keyCode for 'A' = 0)
        RegisterEventHotKey(key,
                           modifiers,
                           hotKeyID,
                           GetApplicationEventTarget(),
                           0,
                           &hotKeyRef)
    }

    func unregister() {
        if let hotKeyRef = hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
        }
        if let eventHandler = eventHandler {
            RemoveEventHandler(eventHandler)
        }
    }

    deinit {
        unregister()
    }
}
