//
//  OverlayWindowCoordinator.swift
//  InsomniMac
//
//  Created by Codex on 3/30/26.
//

import AppKit

@MainActor
final class OverlayWindowCoordinator {
    private let onEscape: () -> Void
    private let onUnexpectedClose: () -> Void

    private var window: OverlayWindow?
    private var isSynchronizing = false
    private var hotKey: HotKey

    init(
        hotKey: HotKey,
        onEscape: @escaping () -> Void,
        onUnexpectedClose: @escaping () -> Void
    ) {
        self.hotKey = hotKey
        self.onEscape = onEscape
        self.onUnexpectedClose = onUnexpectedClose
    }

    func activate() {
        synchronizeWithCurrentScreens()
    }

    func deactivate() {
        isSynchronizing = true
        window?.closeIntentionally()
        window = nil
        isSynchronizing = false
    }

    func synchronizeWithCurrentScreens() {
        isSynchronizing = true

        if window == nil, let screen = NSScreen.main ?? NSScreen.screens.first {
            window = makeWindow(for: screen)
        }

        window?.updateHotKey(hotKey)
        window?.keepOnScreen(using: NSScreen.screens)
        window?.present()

        isSynchronizing = false
    }

    func updateHotKey(_ hotKey: HotKey) {
        self.hotKey = hotKey
        window?.updateHotKey(hotKey)
    }

    private func makeWindow(for screen: NSScreen) -> OverlayWindow {
        let window = OverlayWindow(screen: screen, hotKey: hotKey)
        window.onEscape = onEscape
        window.onUnexpectedClose = { [weak self] in
            guard let self, !self.isSynchronizing else { return }
            self.onUnexpectedClose()
        }
        return window
    }
}
