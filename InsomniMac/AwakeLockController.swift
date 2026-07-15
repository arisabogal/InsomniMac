//
//  AwakeLockController.swift
//  InsomniMac
//
//  Created by Codex on 3/30/26.
//

import AppKit
import Combine
import IOKit
import ServiceManagement

@MainActor
final class AwakeLockController: ObservableObject {
    @Published private(set) var isActive = false
    @Published private(set) var opensAtLogin = false
    @Published private(set) var showOverlayWhenActive = true
    @Published private(set) var preventsLidClosedSleep = false
    @Published private(set) var sharesRemoteModeWithAgents = true
    @Published private(set) var lastStatusMessage: String?
    @Published private(set) var launchAtLoginStatusMessage: String?
    @Published private(set) var currentHotKey: HotKey

    var hotKeyDisplay: String {
        currentHotKey.displayString
    }

    private let hotKeyMonitor: GlobalHotKeyMonitor
    private let sleepAssertionController = SleepAssertionController()
    private let remoteModeInstructionsManager = RemoteModeInstructionsManager()
    private lazy var overlayCoordinator = OverlayWindowCoordinator(
        hotKey: currentHotKey,
        onEscape: { [weak self] in
            self?.deactivate()
        },
        onUnexpectedClose: { [weak self] in
            self?.handleUnexpectedOverlayClose()
        }
    )

    private var screenObserver: NSObjectProtocol?
    private var terminationObserver: NSObjectProtocol?
    private var onboardingWindowController: OnboardingWindowController?

    init() {
        let storedHotKey = HotKey.loadSaved() ?? .defaultAwakeLock
        self.currentHotKey = storedHotKey
        self.hotKeyMonitor = GlobalHotKeyMonitor(hotKey: storedHotKey)

        hotKeyMonitor.onHotKeyPressed = { [weak self] in
            DispatchQueue.main.async {
                self?.toggle()
            }
        }

        if !hotKeyMonitor.register() {
            lastStatusMessage = "Global shortcut unavailable. Use the menu bar to toggle Awake Lock."
        }

        screenObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.handleScreenConfigurationChange()
            }
        }

        terminationObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.removeRemoteModeInstructions()
            }
        }

        configureOverlayPreference()
        configureRemoteModePreference()
        configureLaunchAtLogin()
        removeRemoteModeInstructions()
    }

    deinit {
        if let screenObserver {
            NotificationCenter.default.removeObserver(screenObserver)
        }
        if let terminationObserver {
            NotificationCenter.default.removeObserver(terminationObserver)
        }
    }

    func toggle() {
        isActive ? deactivate() : activate()
    }

    func activate() {
        guard !isActive else { return }

        lastStatusMessage = nil
        NSApp.activate(ignoringOtherApps: true)
        if showOverlayWhenActive {
            overlayCoordinator.activate()
        }
        if let error = sleepAssertionController.activate(
            preventLidClosedSleep: preventsLidClosedSleep
        ) {
            lastStatusMessage = lidClosedSleepErrorMessage(error)
        }
        isActive = true
        synchronizeRemoteModeInstructions()
    }

    func deactivate() {
        guard isActive else { return }

        overlayCoordinator.deactivate()
        sleepAssertionController.deactivate()
        isActive = false
        removeRemoteModeInstructions()
    }

    func quit() {
        deactivate()
        NSApp.terminate(nil)
    }

    func setOpensAtLogin(_ shouldOpenAtLogin: Bool) {
        UserDefaults.standard.set(shouldOpenAtLogin, forKey: Self.opensAtLoginPreferenceKey)
        applyLaunchAtLoginPreference(shouldOpenAtLogin, reportsSuccess: true)
    }

    func setShowOverlayWhenActive(_ shouldShowOverlay: Bool) {
        UserDefaults.standard.set(shouldShowOverlay, forKey: Self.showOverlayPreferenceKey)
        showOverlayWhenActive = shouldShowOverlay

        guard isActive else { return }

        if shouldShowOverlay {
            overlayCoordinator.activate()
        } else {
            overlayCoordinator.deactivate()
        }
    }

    func setPreventsLidClosedSleep(_ shouldPreventSleep: Bool) {
        UserDefaults.standard.set(shouldPreventSleep, forKey: Self.preventLidClosedSleepPreferenceKey)
        preventsLidClosedSleep = shouldPreventSleep

        guard isActive else {
            lastStatusMessage = nil
            return
        }

        if let error = sleepAssertionController.updateLidClosedSleepPrevention(shouldPreventSleep) {
            lastStatusMessage = lidClosedSleepErrorMessage(error)
        } else {
            lastStatusMessage = nil
        }
    }

    func setSharesRemoteModeWithAgents(_ shouldShare: Bool) {
        UserDefaults.standard.set(shouldShare, forKey: Self.remoteModePreferenceKey)
        sharesRemoteModeWithAgents = shouldShare
        synchronizeRemoteModeInstructions()
    }

    func showShortcutSetup() {
        if onboardingWindowController == nil {
            let windowController = OnboardingWindowController(controller: self) { [weak self] in
                self?.onboardingWindowController?.close()
            }

            windowController.onClose = { [weak self] in
                self?.onboardingWindowController = nil
            }
            onboardingWindowController = windowController
        }

        onboardingWindowController?.show()
    }

    func updateShortcut(_ hotKey: HotKey) {
        currentHotKey = hotKey
        hotKey.save()
        overlayCoordinator.updateHotKey(hotKey)

        if !hotKeyMonitor.updateHotKey(hotKey) {
            lastStatusMessage = "Could not register \(hotKey.displayString)."
            currentHotKey = .defaultAwakeLock
            currentHotKey.save()
            overlayCoordinator.updateHotKey(.defaultAwakeLock)
            _ = hotKeyMonitor.updateHotKey(.defaultAwakeLock)
            return
        }

        lastStatusMessage = nil
    }

    func useDefaultShortcut() {
        updateShortcut(.defaultAwakeLock)
    }

    private func handleScreenConfigurationChange() {
        guard isActive, showOverlayWhenActive else { return }
        overlayCoordinator.synchronizeWithCurrentScreens()
    }

    private func handleUnexpectedOverlayClose() {
        deactivate()
        lastStatusMessage = "Awake Lock ended because an overlay closed unexpectedly."
    }

    private static let opensAtLoginPreferenceKey = "opensAtLogin"
    private static let showOverlayPreferenceKey = "showOverlayWhenActive"
    private static let preventLidClosedSleepPreferenceKey = "preventLidClosedSleep"
    private static let remoteModePreferenceKey = "sharesRemoteModeWithAgents"

    private func configureOverlayPreference() {
        if UserDefaults.standard.object(forKey: Self.showOverlayPreferenceKey) == nil {
            UserDefaults.standard.set(true, forKey: Self.showOverlayPreferenceKey)
        }

        showOverlayWhenActive = UserDefaults.standard.bool(forKey: Self.showOverlayPreferenceKey)
        preventsLidClosedSleep = UserDefaults.standard.bool(
            forKey: Self.preventLidClosedSleepPreferenceKey
        )
    }

    private func configureLaunchAtLogin() {
        if UserDefaults.standard.object(forKey: Self.opensAtLoginPreferenceKey) == nil {
            UserDefaults.standard.set(true, forKey: Self.opensAtLoginPreferenceKey)
        }

        let shouldOpenAtLogin = UserDefaults.standard.bool(forKey: Self.opensAtLoginPreferenceKey)
        applyLaunchAtLoginPreference(shouldOpenAtLogin, reportsSuccess: false)
    }

    private func configureRemoteModePreference() {
        if UserDefaults.standard.object(forKey: Self.remoteModePreferenceKey) == nil {
            UserDefaults.standard.set(true, forKey: Self.remoteModePreferenceKey)
        }

        sharesRemoteModeWithAgents = UserDefaults.standard.bool(forKey: Self.remoteModePreferenceKey)
    }

    private func synchronizeRemoteModeInstructions() {
        do {
            try remoteModeInstructionsManager.setRemoteModeActive(
                isActive && sharesRemoteModeWithAgents
            )
        } catch {
            lastStatusMessage = "Could not update the global AGENTS.md: \(error.localizedDescription)"
        }
    }

    private func removeRemoteModeInstructions() {
        do {
            try remoteModeInstructionsManager.setRemoteModeActive(false)
        } catch {
            lastStatusMessage = "Could not remove Remote Mode from the global AGENTS.md: \(error.localizedDescription)"
        }
    }

    private func applyLaunchAtLoginPreference(
        _ shouldOpenAtLogin: Bool,
        reportsSuccess: Bool
    ) {
        launchAtLoginStatusMessage = nil

        do {
            if shouldOpenAtLogin {
                if SMAppService.mainApp.status != .enabled {
                    try SMAppService.mainApp.register()
                }
            } else if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            launchAtLoginStatusMessage = "Could not update Open at Login: \(error.localizedDescription)"
        }

        refreshLaunchAtLoginStatus()

        if reportsSuccess, launchAtLoginStatusMessage == nil {
            launchAtLoginStatusMessage = opensAtLogin ? "InsomniMac will open at login." : "InsomniMac will not open at login."
        }
    }

    private func refreshLaunchAtLoginStatus() {
        switch SMAppService.mainApp.status {
        case .enabled:
            opensAtLogin = true
        case .requiresApproval:
            opensAtLogin = false
            launchAtLoginStatusMessage = "Open at Login needs approval in System Settings."
        case .notFound:
            opensAtLogin = false
            launchAtLoginStatusMessage = "Move InsomniMac to Applications to enable Open at Login."
        case .notRegistered:
            opensAtLogin = false
        @unknown default:
            opensAtLogin = false
        }
    }

    private func lidClosedSleepErrorMessage(_ error: IOReturn) -> String {
        "Awake Lock is active, but macOS did not allow preventing lid-close sleep. IOKit error: \(error)."
    }
}
