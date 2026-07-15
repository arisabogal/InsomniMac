//
//  InsomniMacTests.swift
//  InsomniMacTests
//
//  Created by Ari Sabogal on 3/30/26.
//

import Testing
import Foundation
@testable import InsomniMac

struct InsomniMacTests {

    @Test func remoteModeInstructionIsAddedAndRemovedWithoutChangingOtherContent() throws {
        let fileManager = FileManager.default
        let homeDirectory = fileManager.temporaryDirectory
            .appending(path: UUID().uuidString, directoryHint: .isDirectory)
        let instructionsURL = homeDirectory.appending(path: ".codex/AGENTS.md")
        try fileManager.createDirectory(
            at: instructionsURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try "# Existing instructions\n\nKeep this line.\n".write(
            to: instructionsURL,
            atomically: true,
            encoding: .utf8
        )
        defer { try? fileManager.removeItem(at: homeDirectory) }

        let manager = RemoteModeInstructionsManager(homeDirectory: homeDirectory)
        try manager.setRemoteModeActive(true)
        try manager.setRemoteModeActive(true)

        let activeText = try String(contentsOf: instructionsURL, encoding: .utf8)
        #expect(activeText.components(separatedBy: RemoteModeInstructionsManager.instructionLine).count == 2)
        #expect(activeText.contains("Keep this line."))

        try manager.setRemoteModeActive(false)

        let inactiveText = try String(contentsOf: instructionsURL, encoding: .utf8)
        #expect(inactiveText == "# Existing instructions\n\nKeep this line.\n")
    }

}
