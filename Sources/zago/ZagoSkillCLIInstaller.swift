import Foundation
import Config

public enum ZagoSkillCLIInstaller {
    public static func installSkill(
        customHomePath: String? = nil,
        fileManager: FileManager = .default
    ) throws -> [String] {
        let homeDir: URL
        if let customHome = customHomePath {
            homeDir = URL(fileURLWithPath: customHome)
        } else {
            homeDir = fileManager.homeDirectoryForCurrentUser
        }

        let targetRelativePaths = [
            ".gemini/config/skills/zago",
            ".agents/skills/zago",
            ".claude/skills/zago"
        ]

        var installedPaths: [String] = []

        for relPath in targetRelativePaths {
            let targetDir = homeDir.appendingPathComponent(relPath)
            try fileManager.createDirectory(at: targetDir, withIntermediateDirectories: true)
            let targetFile = targetDir.appendingPathComponent("SKILL.md")
            #if os(Windows)
                let useAtomicWrite = false
            #else
                let useAtomicWrite = true
            #endif
            try ZagoSkillDefinition.markdown.write(to: targetFile, atomically: useAtomicWrite, encoding: .utf8)
            installedPaths.append(targetFile.path)
        }

        return installedPaths
    }
}
