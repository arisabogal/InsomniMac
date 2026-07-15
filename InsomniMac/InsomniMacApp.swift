//
//  InsomniMacApp.swift
//  InsomniMac
//
//  Created by Ari Sabogal on 3/30/26.
//

import AppKit
import Sparkle
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    let updaterController = SPUStandardUpdaterController(
        startingUpdater: true,
        updaterDelegate: nil,
        userDriverDelegate: nil
    )

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }
}

@main
struct InsomniMacApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var awakeLockController = AwakeLockController()

    var body: some Scene {
        MenuBarExtra {
            StatusMenuView(
                controller: awakeLockController,
                updater: appDelegate.updaterController.updater
            )
        } label: {
            Image(systemName: awakeLockController.isActive ? "lock.fill" : "lock.open.fill")
                .accessibilityLabel(
                    awakeLockController.isActive
                    ? "Awake Lock is active"
                    : "Awake Lock is inactive"
                )
        }
    }
}
