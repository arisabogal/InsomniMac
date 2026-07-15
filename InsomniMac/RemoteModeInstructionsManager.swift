//
//  RemoteModeInstructionsManager.swift
//  InsomniMac
//

import Foundation

struct RemoteModeInstructionsManager {
    static let instructionLine = "<!-- InsomniMac Remote Mode --> The Mac is currently in remote mode and the user is not near the computer; account for this in communications, and screen-record actions or send screenshots when visual feedback or information would be valuable."

    private let fileManager: FileManager
    private let homeDirectory: URL

    init(
        fileManager: FileManager = .default,
        homeDirectory: URL = FileManager.default.homeDirectoryForCurrentUser
    ) {
        self.fileManager = fileManager
        self.homeDirectory = homeDirectory
    }

    func setRemoteModeActive(_ isActive: Bool) throws {
        for fileURL in globalInstructionFiles {
            try update(fileURL: fileURL, isActive: isActive)
        }
    }

    private var globalInstructionFiles: [URL] {
        let candidates = [
            homeDirectory.appending(path: ".codex/AGENTS.md"),
            homeDirectory.appending(path: ".agents/AGENTS.md")
        ]
        let existingFiles = candidates.filter { fileManager.fileExists(atPath: $0.path) }

        if !existingFiles.isEmpty {
            return existingFiles
        }

        return [candidates[0]]
    }

    private func update(fileURL: URL, isActive: Bool) throws {
        let existingText: String
        if fileManager.fileExists(atPath: fileURL.path) {
            existingText = try String(contentsOf: fileURL, encoding: .utf8)
        } else {
            try fileManager.createDirectory(
                at: fileURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            existingText = ""
        }

        var lines = existingText.components(separatedBy: .newlines)
        lines.removeAll { $0 == Self.instructionLine }

        while lines.last == "" {
            lines.removeLast()
        }

        if isActive {
            if !lines.isEmpty {
                lines.append("")
            }
            lines.append(Self.instructionLine)
        }

        let updatedText = lines.isEmpty ? "" : lines.joined(separator: "\n") + "\n"
        guard updatedText != existingText else { return }

        try updatedText.write(to: fileURL, atomically: true, encoding: .utf8)
    }
}
