//
//  StatusMenuView.swift
//  InsomniMac
//
//  Created by Codex on 3/30/26.
//

import SwiftUI

struct StatusMenuView: View {
    @ObservedObject var controller: AwakeLockController

    var body: some View {
        Text(controller.isActive ? "Awake Lock Active" : "Awake Lock Inactive")

        Text("Hotkey: \(controller.hotKeyDisplay)")
            .foregroundStyle(.secondary)

        Divider()

        Button(controller.isActive ? "Exit Awake Lock" : "Enter Awake Lock") {
            controller.toggle()
        }

        Button("Set Shortcut") {
            controller.showShortcutSetup()
        }

        Toggle(
            "Open at Login",
            isOn: Binding(
                get: { controller.opensAtLogin },
                set: { controller.setOpensAtLogin($0) }
            )
        )

        Toggle(
            "Show Overlay When Active",
            isOn: Binding(
                get: { controller.showOverlayWhenActive },
                set: { controller.setShowOverlayWhenActive($0) }
            )
        )

        Toggle(
            "Prevent Sleep When Lid Closes",
            isOn: Binding(
                get: { controller.preventsLidClosedSleep },
                set: { controller.setPreventsLidClosedSleep($0) }
            )
        )

        Toggle(
            "Share Remote Mode with Agents",
            isOn: Binding(
                get: { controller.sharesRemoteModeWithAgents },
                set: { controller.setSharesRemoteModeWithAgents($0) }
            )
        )
        .help("While Awake Lock is active, tell agents that you are away and visual updates may be useful.")

        if let lastStatusMessage = controller.lastStatusMessage {
            Divider()

            Text(lastStatusMessage)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }

        if let launchAtLoginStatusMessage = controller.launchAtLoginStatusMessage {
            Divider()

            Text(launchAtLoginStatusMessage)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }

        Divider()

        Button("Quit InsomniMac") {
            controller.quit()
        }
    }
}
