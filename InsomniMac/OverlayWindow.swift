//
//  OverlayWindow.swift
//  InsomniMac
//
//  Created by Codex on 3/30/26.
//

import AppKit
import Carbon
import SwiftUI

@MainActor
final class OverlayWindow: NSWindow, NSWindowDelegate {
    static let overlaySize = NSSize(width: 128, height: 144)

    var onEscape: (() -> Void)?
    var onUnexpectedClose: (() -> Void)?

    private var isClosingIntentionally = false
    private var hotKey: HotKey
    private let hostingView: NSHostingView<AwakeSpriteView>

    init(screen: NSScreen, hotKey: HotKey) {
        self.hotKey = hotKey
        hostingView = NSHostingView(rootView: AwakeSpriteView(hotKey: hotKey))

        super.init(
            contentRect: NSRect(origin: .zero, size: Self.overlaySize),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        backgroundColor = .clear
        contentView = hostingView
        delegate = self
        hasShadow = false
        isMovable = true
        isMovableByWindowBackground = true
        isOpaque = false
        isReleasedWhenClosed = false
        level = .floating
        collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary,
            .ignoresCycle
        ]

        restorePosition(orPlaceOn: screen)
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    override func sendEvent(_ event: NSEvent) {
        switch event.type {
        case .leftMouseDown:
            performDrag(with: event)
            return
        case .flagsChanged, .keyUp:
            return
        case .keyDown:
            if event.keyCode == UInt16(kVK_Escape) || matchesConfiguredShortcut(event) {
                onEscape?()
            }
            return
        default:
            super.sendEvent(event)
        }
    }

    override func cancelOperation(_ sender: Any?) {
        onEscape?()
    }

    func present() {
        orderFrontRegardless()
    }

    func updateHotKey(_ hotKey: HotKey) {
        self.hotKey = hotKey
        hostingView.rootView = AwakeSpriteView(hotKey: hotKey)
    }

    func keepOnScreen(using screens: [NSScreen]) {
        guard let screen = screens.first(where: { $0.visibleFrame.intersects(frame) }) else {
            place(on: screens.first ?? NSScreen.main)
            return
        }

        let visibleFrame = screen.visibleFrame
        let clampedOrigin = NSPoint(
            x: min(max(frame.minX, visibleFrame.minX), visibleFrame.maxX - frame.width),
            y: min(max(frame.minY, visibleFrame.minY), visibleFrame.maxY - frame.height)
        )

        if clampedOrigin != frame.origin {
            setFrameOrigin(clampedOrigin)
        }
    }

    func closeIntentionally() {
        isClosingIntentionally = true
        orderOut(nil)
        close()
    }

    func windowDidMove(_ notification: Notification) {
        UserDefaults.standard.set(frame.origin.x, forKey: Self.savedOriginXKey)
        UserDefaults.standard.set(frame.origin.y, forKey: Self.savedOriginYKey)
    }

    func windowWillClose(_ notification: Notification) {
        guard !isClosingIntentionally else { return }
        onUnexpectedClose?()
    }

    private func restorePosition(orPlaceOn screen: NSScreen) {
        let defaults = UserDefaults.standard
        if
            defaults.object(forKey: Self.savedOriginXKey) != nil,
            defaults.object(forKey: Self.savedOriginYKey) != nil
        {
            setFrameOrigin(
                NSPoint(
                    x: defaults.double(forKey: Self.savedOriginXKey),
                    y: defaults.double(forKey: Self.savedOriginYKey)
                )
            )
            keepOnScreen(using: NSScreen.screens)
        } else {
            place(on: screen)
        }
    }

    private func place(on screen: NSScreen?) {
        guard let visibleFrame = screen?.visibleFrame else { return }
        setFrameOrigin(
            NSPoint(
                x: visibleFrame.maxX - frame.width - 24,
                y: visibleFrame.maxY - frame.height - 24
            )
        )
    }

    private func matchesConfiguredShortcut(_ event: NSEvent) -> Bool {
        guard UInt32(event.keyCode) == hotKey.keyCode else { return false }
        return normalizedCarbonModifiers(for: event) == hotKey.modifiers
    }

    private func normalizedCarbonModifiers(for event: NSEvent) -> UInt32 {
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        var normalized: UInt32 = 0

        if flags.contains(.command) { normalized |= UInt32(cmdKey) }
        if flags.contains(.shift) { normalized |= UInt32(shiftKey) }
        if flags.contains(.option) { normalized |= UInt32(optionKey) }
        if flags.contains(.control) { normalized |= UInt32(controlKey) }

        return normalized
    }

    private static let savedOriginXKey = "awakeSpriteOriginX"
    private static let savedOriginYKey = "awakeSpriteOriginY"
}

private struct AwakeSpriteView: View {
    @State private var isHovering = false

    private static let frames = SpriteSheet.frames(named: "AwakeSpriteSheet", columns: 4, rows: 4)

    // Repeating a frame gives the important story beats room to read at icon size.
    private static let playback: [Int] = [
        0, 0, 0, 0, 0, 0,
        1, 1, 1,
        2, 2, 2,
        3, 3, 3, 3,
        4, 4, 4,
        5, 5, 5, 5,
        6, 6, 6, 6, 6, 6,
        7, 7, 7,
        8, 8,
        9, 9,
        10, 10,
        11, 11, 11,
        12, 12, 12,
        13, 13,
        14, 14, 14,
        15, 15, 15, 15, 15
    ]

    let hotKey: HotKey

    var body: some View {
        VStack(spacing: 2) {
            TimelineView(.animation(minimumInterval: 0.1, paused: Self.frames.isEmpty)) { context in
                if let image = currentImage(at: context.date) {
                    Image(nsImage: image)
                        .resizable()
                        .interpolation(.high)
                        .scaledToFit()
                        .padding(2)
                        .accessibilityLabel("A caffeinated MacBook keeping the Mac awake")
                }
            }
            .frame(width: 112, height: 112)

            ShortcutKeyCapsView(parts: hotKey.keyParts, style: .overlayCompact)
                .opacity(isHovering ? 1 : 0)
                .offset(y: isHovering ? 0 : 4)
                .allowsHitTesting(false)
                .accessibilityLabel("Shortcut to allow sleep: \(hotKey.displayString)")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onHover { isHovering = $0 }
        .animation(.easeOut(duration: 0.16), value: isHovering)
        .help("Drag the awake Mac anywhere")
    }

    private func currentImage(at date: Date) -> NSImage? {
        guard !Self.frames.isEmpty else { return nil }
        let tick = Int(date.timeIntervalSinceReferenceDate / 0.1)
        let frameIndex = Self.playback[tick % Self.playback.count]
        return Self.frames[frameIndex]
    }
}

private enum SpriteSheet {
    static func frames(named name: NSImage.Name, columns: Int, rows: Int) -> [NSImage] {
        guard
            let source = NSImage(named: name),
            let cgImage = source.cgImage(forProposedRect: nil, context: nil, hints: nil)
        else {
            return []
        }

        var result: [NSImage] = []
        for row in 0..<rows {
            for column in 0..<columns {
                let x0 = column * cgImage.width / columns
                let x1 = (column + 1) * cgImage.width / columns
                // CGImage coordinates begin at the top-left, matching sprite-sheet reading order.
                let y0 = row * cgImage.height / rows
                let y1 = (row + 1) * cgImage.height / rows
                let rect = CGRect(x: x0, y: y0, width: x1 - x0, height: y1 - y0)

                guard let cropped = cgImage.cropping(to: rect) else { continue }
                result.append(NSImage(cgImage: cropped, size: .zero))
            }
        }

        return result
    }
}
