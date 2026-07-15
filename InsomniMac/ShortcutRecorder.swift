//
//  ShortcutRecorder.swift
//  InsomniMac
//
//  Created by Codex on 3/30/26.
//

import AppKit
import Carbon
import Combine

@MainActor
final class ShortcutRecorder: ObservableObject {
    @Published private(set) var isRecording = false
    @Published private(set) var helperText = "Press command, one modifier, and one key."
    @Published private(set) var invalidCommandAttempts = 0

    private var keyMonitor: Any?

    func startRecording(onCapture: @escaping (HotKey) -> Void) {
        stopRecording()

        helperText = "Press command, one modifier, and one key."
        isRecording = true

        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return event }
            return self.handle(event: event, onCapture: onCapture)
        }
    }

    func stopRecording() {
        if let keyMonitor {
            NSEvent.removeMonitor(keyMonitor)
            self.keyMonitor = nil
        }

        isRecording = false
    }

    private func handle(event: NSEvent, onCapture: @escaping (HotKey) -> Void) -> NSEvent? {
        let modifierFlags = event.modifierFlags.intersection([.command, .shift, .option, .control])
        let modifierCount = [
            NSEvent.ModifierFlags.command,
            .shift,
            .option,
            .control
        ]
        .filter(modifierFlags.contains)
        .count

        guard modifierCount == 2 else {
            helperText = "Use exactly 3 keys: command, one modifier, and one key."
            return nil
        }

        guard modifierFlags.contains(.command) else {
            helperText = "Press command, one modifier, and one key."
            invalidCommandAttempts += 1
            return nil
        }

        let modifiers = carbonFlags(for: modifierFlags)
        let shortcut = HotKey(
            keyCode: UInt32(event.keyCode),
            modifiers: modifiers
        )

        helperText = "Shortcut set to \(shortcut.displayString)"
        onCapture(shortcut)
        return nil
    }

    func showMessage(_ text: String) {
        helperText = text
    }

    private func carbonFlags(for flags: NSEvent.ModifierFlags) -> UInt32 {
        var carbonFlags: UInt32 = 0

        if flags.contains(.command) {
            carbonFlags |= UInt32(cmdKey)
        }
        if flags.contains(.shift) {
            carbonFlags |= UInt32(shiftKey)
        }
        if flags.contains(.option) {
            carbonFlags |= UInt32(optionKey)
        }
        if flags.contains(.control) {
            carbonFlags |= UInt32(controlKey)
        }

        return carbonFlags
    }
}
