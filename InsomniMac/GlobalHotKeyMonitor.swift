//
//  GlobalHotKeyMonitor.swift
//  InsomniMac
//
//  Created by Codex on 3/30/26.
//

import Carbon
import Foundation

struct HotKey: Equatable {
    let keyCode: UInt32
    let modifiers: UInt32

    var displayString: String {
        modifierSymbols + keySymbol
    }

    var keyParts: [String] {
        var parts: [String] = []

        if modifiers & UInt32(cmdKey) != 0 {
            parts.append("⌘")
        }
        if modifiers & UInt32(shiftKey) != 0 {
            parts.append("⇧")
        }
        if modifiers & UInt32(optionKey) != 0 {
            parts.append("⌥")
        }
        if modifiers & UInt32(controlKey) != 0 {
            parts.append("⌃")
        }

        parts.append(keySymbol)
        return parts
    }

    var keyPartsExcludingCommand: [String] {
        keyParts.filter { $0 != "⌘" }
    }

    static let defaultAwakeLock = HotKey(
        keyCode: UInt32(kVK_ANSI_Backslash),
        modifiers: UInt32(cmdKey | shiftKey)
    )

    private static let storageKeyCode = "awakeLockShortcutKeyCode"
    private static let storageModifiers = "awakeLockShortcutModifiers"
    private static let didCompleteOnboardingKey = "awakeLockDidCompleteOnboarding"

    var modifierSymbols: String {
        var symbols = ""

        if modifiers & UInt32(cmdKey) != 0 {
            symbols += "⌘"
        }
        if modifiers & UInt32(shiftKey) != 0 {
            symbols += "⇧"
        }
        if modifiers & UInt32(optionKey) != 0 {
            symbols += "⌥"
        }
        if modifiers & UInt32(controlKey) != 0 {
            symbols += "⌃"
        }

        return symbols
    }

    var keySymbol: String {
        switch Int(keyCode) {
        case kVK_ANSI_A: "A"
        case kVK_ANSI_B: "B"
        case kVK_ANSI_C: "C"
        case kVK_ANSI_D: "D"
        case kVK_ANSI_E: "E"
        case kVK_ANSI_F: "F"
        case kVK_ANSI_G: "G"
        case kVK_ANSI_H: "H"
        case kVK_ANSI_I: "I"
        case kVK_ANSI_J: "J"
        case kVK_ANSI_K: "K"
        case kVK_ANSI_L: "L"
        case kVK_ANSI_M: "M"
        case kVK_ANSI_N: "N"
        case kVK_ANSI_O: "O"
        case kVK_ANSI_P: "P"
        case kVK_ANSI_Q: "Q"
        case kVK_ANSI_R: "R"
        case kVK_ANSI_S: "S"
        case kVK_ANSI_T: "T"
        case kVK_ANSI_U: "U"
        case kVK_ANSI_V: "V"
        case kVK_ANSI_W: "W"
        case kVK_ANSI_X: "X"
        case kVK_ANSI_Y: "Y"
        case kVK_ANSI_Z: "Z"
        case kVK_ANSI_0: "0"
        case kVK_ANSI_1: "1"
        case kVK_ANSI_2: "2"
        case kVK_ANSI_3: "3"
        case kVK_ANSI_4: "4"
        case kVK_ANSI_5: "5"
        case kVK_ANSI_6: "6"
        case kVK_ANSI_7: "7"
        case kVK_ANSI_8: "8"
        case kVK_ANSI_9: "9"
        case kVK_ANSI_Backslash: "\\"
        case kVK_ANSI_Comma: ","
        case kVK_ANSI_Period: "."
        case kVK_ANSI_Slash: "/"
        case kVK_ANSI_Semicolon: ";"
        case kVK_ANSI_Quote: "'"
        case kVK_ANSI_LeftBracket: "["
        case kVK_ANSI_RightBracket: "]"
        case kVK_ANSI_Minus: "-"
        case kVK_ANSI_Equal: "="
        case kVK_Space: "Space"
        case kVK_Return: "Return"
        case kVK_Tab: "Tab"
        case kVK_Delete: "Delete"
        case kVK_Escape: "Esc"
        default: "Key \(keyCode)"
        }
    }

    static var didCompleteOnboarding: Bool {
        UserDefaults.standard.bool(forKey: didCompleteOnboardingKey)
    }

    static func loadSaved() -> HotKey? {
        let defaults = UserDefaults.standard

        guard
            defaults.object(forKey: storageKeyCode) != nil,
            defaults.object(forKey: storageModifiers) != nil
        else {
            return nil
        }

        return HotKey(
            keyCode: UInt32(defaults.integer(forKey: storageKeyCode)),
            modifiers: UInt32(defaults.integer(forKey: storageModifiers))
        )
    }

    func save(markOnboardingComplete: Bool = true) {
        let defaults = UserDefaults.standard
        defaults.set(Int(keyCode), forKey: Self.storageKeyCode)
        defaults.set(Int(modifiers), forKey: Self.storageModifiers)

        if markOnboardingComplete {
            defaults.set(true, forKey: Self.didCompleteOnboardingKey)
        }
    }
}

final class GlobalHotKeyMonitor {
    var onHotKeyPressed: (() -> Void)?

    private var hotKey: HotKey
    private let hotKeyID = EventHotKeyID(signature: 0x41574C4B, id: 1)
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?

    init(hotKey: HotKey) {
        self.hotKey = hotKey
    }

    deinit {
        unregister()
    }

    func register() -> Bool {
        unregister()

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        let installStatus = InstallEventHandler(
            GetApplicationEventTarget(),
            Self.hotKeyHandler,
            1,
            &eventType,
            Unmanaged.passUnretained(self).toOpaque(),
            &eventHandlerRef
        )

        guard installStatus == noErr else {
            unregister()
            return false
        }

        let registerStatus = RegisterEventHotKey(
            hotKey.keyCode,
            hotKey.modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )

        guard registerStatus == noErr else {
            unregister()
            return false
        }

        return true
    }

    func updateHotKey(_ hotKey: HotKey) -> Bool {
        self.hotKey = hotKey
        return register()
    }

    func unregister() {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }

        if let eventHandlerRef {
            RemoveEventHandler(eventHandlerRef)
            self.eventHandlerRef = nil
        }
    }

    private func handleHotKeyEvent(_ event: EventRef?) -> OSStatus {
        guard let event else { return noErr }

        var receivedHotKeyID = EventHotKeyID()
        let status = GetEventParameter(
            event,
            EventParamName(kEventParamDirectObject),
            EventParamType(typeEventHotKeyID),
            nil,
            MemoryLayout<EventHotKeyID>.size,
            nil,
            &receivedHotKeyID
        )

        guard status == noErr, receivedHotKeyID.id == hotKeyID.id else {
            return noErr
        }

        onHotKeyPressed?()
        return noErr
    }

    private static let hotKeyHandler: EventHandlerUPP = { _, event, userData in
        guard let userData else { return noErr }

        let monitor = Unmanaged<GlobalHotKeyMonitor>
            .fromOpaque(userData)
            .takeUnretainedValue()

        return monitor.handleHotKeyEvent(event)
    }
}
