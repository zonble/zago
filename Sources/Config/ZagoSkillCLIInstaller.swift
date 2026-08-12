import Foundation

public enum ZagoSkillCLIInstaller {
    private static let skillRelativePaths = [
        ".codex/skills/zago",
        ".gemini/config/skills/zago",
        ".agents/skills/zago",
        ".claude/skills/zago",
    ]

    public static func installSkill(
        customHomePath: String? = nil,
        fileManager: FileManager = .default
    ) throws -> [String] {
        let homeDir = homeDirectory(customHomePath, fileManager: fileManager)

        var installedPaths: [String] = []

        for relPath in skillRelativePaths {
            let targetDir = homeDir.appendingPathComponent(relPath)
            try fileManager.createDirectory(at: targetDir, withIntermediateDirectories: true)
            let targetFile = targetDir.appendingPathComponent("SKILL.md")
            try ZagoSkillDefinition.markdown.write(
                to: targetFile,
                atomically: usesAtomicWrites,
                encoding: .utf8
            )
            installedPaths.append(targetFile.path)
        }

        return installedPaths
    }

    /// Removes only the zago skill files. Parent directories are retained unless the
    /// per-agent `zago` directory is empty after removing `SKILL.md`.
    public static func uninstallSkill(
        customHomePath: String? = nil,
        fileManager: FileManager = .default
    ) throws -> [String] {
        let homeDir = homeDirectory(customHomePath, fileManager: fileManager)
        var removedPaths: [String] = []

        for relPath in skillRelativePaths {
            let targetDir = homeDir.appendingPathComponent(relPath)
            let targetFile = targetDir.appendingPathComponent("SKILL.md")
            guard fileManager.fileExists(atPath: targetFile.path) else { continue }

            try fileManager.removeItem(at: targetFile)
            removedPaths.append(targetFile.path)

            if try fileManager.contentsOfDirectory(atPath: targetDir.path).isEmpty {
                try fileManager.removeItem(at: targetDir)
            }
        }

        return removedPaths
    }

    public static func installMCP(
        customHomePath: String? = nil,
        zagoCommand: String = "zago",
        fileManager: FileManager = .default
    ) throws -> [String] {
        let homeDir = homeDirectory(customHomePath, fileManager: fileManager)

        var installedPaths: [String] = []

        for relPath in jsonMCPConfigRelativePaths {
            let targetFile = homeDir.appendingPathComponent(relPath)
            let targetDir = targetFile.deletingLastPathComponent()

            try fileManager.createDirectory(at: targetDir, withIntermediateDirectories: true)

            var rootObj: [String: Any] = [:]
            if fileManager.fileExists(atPath: targetFile.path),
                let data = try? Data(contentsOf: targetFile),
                let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            {
                rootObj = json
            }

            var mcpServers = rootObj["mcpServers"] as? [String: Any] ?? [:]
            mcpServers["zago"] = [
                "command": zagoCommand,
                "args": ["--mcp"],
            ]
            rootObj["mcpServers"] = mcpServers

            let jsonData = try JSONSerialization.data(withJSONObject: rootObj, options: [.prettyPrinted, .sortedKeys])
            try jsonData.write(to: targetFile, options: atomicWriteOptions)
            installedPaths.append(targetFile.path)
        }

        let codexConfigFile = homeDir.appendingPathComponent(codexConfigRelativePath)
        let codexConfigDir = codexConfigFile.deletingLastPathComponent()
        try fileManager.createDirectory(at: codexConfigDir, withIntermediateDirectories: true)

        let existingCodexConfig: String
        if fileManager.fileExists(atPath: codexConfigFile.path) {
            existingCodexConfig = try String(contentsOf: codexConfigFile, encoding: .utf8)
        } else {
            existingCodexConfig = ""
        }
        let updatedCodexConfig = codexConfigWithZagoMCP(
            existingCodexConfig,
            zagoCommand: zagoCommand
        )
        try updatedCodexConfig.write(
            to: codexConfigFile,
            atomically: usesAtomicWrites,
            encoding: .utf8
        )
        installedPaths.append(codexConfigFile.path)

        return installedPaths
    }

    /// Removes the `zago` entry from each known MCP configuration while preserving
    /// every other top-level value and MCP server entry.
    public static func uninstallMCP(
        customHomePath: String? = nil,
        fileManager: FileManager = .default
    ) throws -> [String] {
        let homeDir = homeDirectory(customHomePath, fileManager: fileManager)
        var updatedPaths: [String] = []

        for relPath in jsonMCPConfigRelativePaths {
            let targetFile = homeDir.appendingPathComponent(relPath)
            guard fileManager.fileExists(atPath: targetFile.path) else { continue }

            let data = try Data(contentsOf: targetFile)
            guard var rootObject = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            else {
                throw CocoaError(.fileReadCorruptFile)
            }
            guard var mcpServers = rootObject["mcpServers"] as? [String: Any],
                mcpServers.removeValue(forKey: "zago") != nil
            else {
                continue
            }

            rootObject["mcpServers"] = mcpServers
            let jsonData = try JSONSerialization.data(
                withJSONObject: rootObject,
                options: [.prettyPrinted, .sortedKeys]
            )
            try jsonData.write(to: targetFile, options: atomicWriteOptions)
            updatedPaths.append(targetFile.path)
        }

        let codexConfigFile = homeDir.appendingPathComponent(codexConfigRelativePath)
        if fileManager.fileExists(atPath: codexConfigFile.path) {
            let existingCodexConfig = try String(contentsOf: codexConfigFile, encoding: .utf8)
            let (updatedCodexConfig, removed) = codexConfigRemovingZagoMCP(existingCodexConfig)
            if removed {
                try updatedCodexConfig.write(
                    to: codexConfigFile,
                    atomically: usesAtomicWrites,
                    encoding: .utf8
                )
                updatedPaths.append(codexConfigFile.path)
            }
        }

        return updatedPaths
    }

    public static func installSkillAndMCP(
        customHomePath: String? = nil,
        zagoCommand: String = "zago",
        fileManager: FileManager = .default
    ) throws -> (skillPaths: [String], mcpPaths: [String]) {
        let skillPaths = try installSkill(customHomePath: customHomePath, fileManager: fileManager)
        let mcpPaths = try installMCP(
            customHomePath: customHomePath, zagoCommand: zagoCommand, fileManager: fileManager)
        return (skillPaths, mcpPaths)
    }

    private static func homeDirectory(
        _ customHomePath: String?,
        fileManager: FileManager
    ) -> URL {
        customHomePath.map(URL.init(fileURLWithPath:))
            ?? fileManager.homeDirectoryForCurrentUser
    }

    private static let codexConfigRelativePath = ".codex/config.toml"

    private static var jsonMCPConfigRelativePaths: [String] {
        var paths = [
            ".gemini/config/mcp_config.json",
            ".agents/mcp_config.json",
            ".claude/mcp_config.json",
        ]

        #if os(macOS)
            paths.append("Library/Application Support/Claude/claude_desktop_config.json")
        #elseif os(Windows)
            paths.append("AppData/Roaming/Claude/claude_desktop_config.json")
        #endif

        return paths
    }

    private static func codexConfigWithZagoMCP(
        _ existing: String,
        zagoCommand: String
    ) -> String {
        let (withoutZago, _) = codexConfigRemovingZagoMCP(existing)
        var output = withoutZago.trimmingCharacters(in: .whitespacesAndNewlines)

        if !output.isEmpty {
            output += "\n\n"
        }

        output += """
            [mcp_servers.zago]
            command = "\(tomlEscapedString(zagoCommand))"
            args = ["--mcp"]
            """

        return output + "\n"
    }

    private static func codexConfigRemovingZagoMCP(_ existing: String) -> (String, Bool) {
        guard !existing.isEmpty else {
            return ("", false)
        }

        let lines = existing.split(separator: "\n", omittingEmptySubsequences: false)
            .map(String.init)
        var outputLines: [String] = []
        var removed = false
        var skippingZagoSection = false

        for line in lines {
            if let sectionName = tomlSectionName(line) {
                skippingZagoSection = isZagoMCPSection(sectionName)
                if skippingZagoSection {
                    removed = true
                    continue
                }
            }

            if !skippingZagoSection {
                outputLines.append(line)
            }
        }

        guard removed else {
            return (existing, false)
        }

        let output = outputLines.joined(separator: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return (output.isEmpty ? "" : output + "\n", true)
    }

    private static func tomlSectionName(_ line: String) -> String? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard trimmed.hasPrefix("["),
            trimmed.hasSuffix("]"),
            !trimmed.hasPrefix("[["),
            !trimmed.hasSuffix("]]")
        else {
            return nil
        }

        return String(trimmed.dropFirst().dropLast()).trimmingCharacters(in: .whitespaces)
    }

    private static func isZagoMCPSection(_ sectionName: String) -> Bool {
        sectionName == "mcp_servers.zago"
            || sectionName.hasPrefix("mcp_servers.zago.")
    }

    private static func tomlEscapedString(_ value: String) -> String {
        value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "\\r")
            .replacingOccurrences(of: "\t", with: "\\t")
    }

    private static var atomicWriteOptions: Data.WritingOptions {
        #if os(Windows)
            []
        #else
            .atomic
        #endif
    }

    private static var usesAtomicWrites: Bool {
        #if os(Windows)
            false
        #else
            true
        #endif
    }
}
