//
//  SleepAssertionController.swift
//  InsomniMac
//
//  Created by Codex on 3/30/26.
//

import Foundation
import IOKit
import IOKit.pwr_mgt

@MainActor
final class SleepAssertionController {
    private static let setClamshellSleepStateMethod: UInt32 = 12

    private var activityToken: NSObjectProtocol?
    private var systemSleepAssertionID: IOPMAssertionID = 0
    private var displaySleepAssertionID: IOPMAssertionID = 0
    private var didDisableClamshellSleep = false

    func activate(preventLidClosedSleep: Bool) -> IOReturn? {
        guard activityToken == nil else { return nil }

        activityToken = ProcessInfo.processInfo.beginActivity(
            options: [.idleSystemSleepDisabled, .idleDisplaySleepDisabled],
            reason: "Awake Lock is active"
        )

        createAssertion(
            type: kIOPMAssertPreventUserIdleSystemSleep as CFString,
            name: "InsomniMac System Sleep Lock",
            id: &systemSleepAssertionID
        )

        createAssertion(
            type: kIOPMAssertionTypePreventUserIdleDisplaySleep as CFString,
            name: "InsomniMac Display Sleep Lock",
            id: &displaySleepAssertionID
        )

        guard preventLidClosedSleep else { return nil }

        let result = setClamshellSleepDisabled(true)
        if result == kIOReturnSuccess {
            didDisableClamshellSleep = true
            return nil
        }

        return result
    }

    func deactivate() {
        if didDisableClamshellSleep {
            if setClamshellSleepDisabled(false) == kIOReturnSuccess {
                didDisableClamshellSleep = false
            }
        }

        if let activityToken {
            ProcessInfo.processInfo.endActivity(activityToken)
            self.activityToken = nil
        }

        releaseAssertion(&systemSleepAssertionID)
        releaseAssertion(&displaySleepAssertionID)
    }

    func updateLidClosedSleepPrevention(_ isEnabled: Bool) -> IOReturn? {
        guard activityToken != nil else { return nil }

        if isEnabled {
            guard !didDisableClamshellSleep else { return nil }

            let result = setClamshellSleepDisabled(true)
            if result == kIOReturnSuccess {
                didDisableClamshellSleep = true
                return nil
            }

            return result
        }

        if didDisableClamshellSleep {
            let result = setClamshellSleepDisabled(false)

            if result != kIOReturnSuccess {
                return result
            }

            didDisableClamshellSleep = false
        }

        return nil
    }

    private func createAssertion(
        type: CFString,
        name: String,
        id: inout IOPMAssertionID
    ) {
        guard id == 0 else { return }

        let result = IOPMAssertionCreateWithName(
            type,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            name as CFString,
            &id
        )

        if result != kIOReturnSuccess {
            id = 0
        }
    }

    private func releaseAssertion(_ id: inout IOPMAssertionID) {
        guard id != 0 else { return }
        IOPMAssertionRelease(id)
        id = 0
    }

    private func setClamshellSleepDisabled(_ isDisabled: Bool) -> IOReturn {
        let powerManagementConnection = IOPMFindPowerManagement(mach_port_t(MACH_PORT_NULL))
        guard powerManagementConnection != IO_OBJECT_NULL else {
            return kIOReturnNotFound
        }
        defer { IOServiceClose(powerManagementConnection) }

        var input: [UInt64] = [isDisabled ? 1 : 0]
        return input.withUnsafeMutableBufferPointer { buffer in
            IOConnectCallScalarMethod(
                powerManagementConnection,
                Self.setClamshellSleepStateMethod,
                buffer.baseAddress,
                1,
                nil,
                nil
            )
        }
    }
}
