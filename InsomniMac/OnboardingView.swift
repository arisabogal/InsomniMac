//
//  OnboardingView.swift
//  InsomniMac
//
//  Created by Codex on 3/30/26.
//

import Combine
import SwiftUI

struct OnboardingView: View {
    @ObservedObject var controller: AwakeLockController
    @StateObject private var recorder = ShortcutRecorder()
    @State private var displayedHotKey: HotKey
    @State private var closeTask: Task<Void, Never>?
    @State private var commandShakeTrigger = 0

    let onDone: () -> Void

    init(controller: AwakeLockController, onDone: @escaping () -> Void) {
        self.controller = controller
        self.onDone = onDone
        _displayedHotKey = State(initialValue: controller.currentHotKey)
    }

    var body: some View {
        VStack(spacing: 18) {
            Spacer()

            Image("InsomniMac")
                .resizable()
                .scaledToFit()
                .frame(width: 92, height: 92)

            Text("insomnimac")
                .font(.system(size: 26, weight: .bold, design: .rounded))

            Text("Your Shortcut")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)

            HStack(alignment: .bottom, spacing: 12) {
                VStack(spacing: 5) {
                    Text("required")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                        .opacity(0.65)

                    ShortcutKeyCapsView(parts: ["⌘"])
                        .opacity(0.45)
                        .modifier(ShakeEffect(animatableData: CGFloat(commandShakeTrigger)))
                }

                ShortcutKeyCapsView(parts: displayedHotKey.keyPartsExcludingCommand)
            }
            .padding(.top, 10)

            Button("Use Default \(HotKey.defaultAwakeLock.displayString)") {
                closeTask?.cancel()
                controller.useDefaultShortcut()
                displayedHotKey = controller.currentHotKey
                recorder.showMessage("Default shortcut saved. Closing in 3 seconds...")
                scheduleClose()
            }

            Text(recorder.helperText)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 260)

            Spacer()
        }
        .padding(28)
        .frame(width: 360, height: 360)
        .onAppear {
            guard !recorder.isRecording else { return }
            startListening()
        }
        .onDisappear {
            closeTask?.cancel()
            recorder.stopRecording()
        }
        .onReceive(recorder.$invalidCommandAttempts.dropFirst()) { _ in
            withAnimation(.easeInOut(duration: 0.38)) {
                commandShakeTrigger += 1
            }
        }
    }

    private func startListening() {
        closeTask?.cancel()
        recorder.showMessage("Press command, one modifier, and one key.")
        recorder.startRecording { hotKey in
            controller.updateShortcut(hotKey)
            displayedHotKey = controller.currentHotKey
            recorder.showMessage("Shortcut saved. Closing in 3 seconds...")
            scheduleClose()
        }
    }

    private func scheduleClose() {
        closeTask?.cancel()
        closeTask = Task {
            try? await Task.sleep(for: .seconds(3))
            guard !Task.isCancelled else { return }
            onDone()
        }
    }
}

private struct ShakeEffect: GeometryEffect {
    var travelDistance: CGFloat = 8
    var shakesPerUnit = 3
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(
            CGAffineTransform(
                translationX: travelDistance * sin(animatableData * .pi * CGFloat(shakesPerUnit)),
                y: 0
            )
        )
    }
}
