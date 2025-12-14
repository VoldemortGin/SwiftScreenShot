//
//  HotKeyManager.swift
//  SwiftScreenShot
//
//  Global hotkey manager using Carbon Event Manager
//

import Carbon
import Cocoa

class HotKeyManager {
    private var hotKeys: [(ref: EventHotKeyRef?, id: UInt32)] = []
    private var eventHandler: EventHandlerRef?
    private var callbacks: [UInt32: () -> Void] = [:]

    func register(key: UInt32, modifiers: UInt32, id: UInt32 = 1, callback: @escaping () -> Void) {
        // Store callback
        callbacks[id] = callback

        // First time setup event handler
        if eventHandler == nil {
            var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                           eventKind: UInt32(kEventHotKeyPressed))

            InstallEventHandler(GetApplicationEventTarget(),
                                { (nextHandler, theEvent, userData) -> OSStatus in
                let manager = Unmanaged<HotKeyManager>
                    .fromOpaque(userData!)
                    .takeUnretainedValue()

                // Get the hotkey ID from the event
                var hotKeyID = EventHotKeyID()
                GetEventParameter(theEvent,
                                 UInt32(kEventParamDirectObject),
                                 UInt32(typeEventHotKeyID),
                                 nil,
                                 MemoryLayout<EventHotKeyID>.size,
                                 nil,
                                 &hotKeyID)

                // Call the corresponding callback
                manager.callbacks[hotKeyID.id]?()
                return noErr
            }, 1, &eventType,
            Unmanaged.passUnretained(self).toOpaque(),
            &eventHandler)
        }

        // Register hotkey
        var hotKeyID = EventHotKeyID(signature: 0x53535353, id: id)
        var hotKeyRef: EventHotKeyRef?

        RegisterEventHotKey(key,
                           modifiers,
                           hotKeyID,
                           GetApplicationEventTarget(),
                           0,
                           &hotKeyRef)

        hotKeys.append((ref: hotKeyRef, id: id))
    }

    func unregister() {
        for hotKey in hotKeys {
            if let ref = hotKey.ref {
                UnregisterEventHotKey(ref)
            }
        }
        hotKeys.removeAll()
        callbacks.removeAll()

        if let eventHandler = eventHandler {
            RemoveEventHandler(eventHandler)
            self.eventHandler = nil
        }
    }

    deinit {
        unregister()
    }
}
