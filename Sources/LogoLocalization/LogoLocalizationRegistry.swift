import Foundation
import LogoEngine

/// Central factory for discovering and instantiating built-in localized Logo plugins / dialects.
public enum LogoLocalizationRegistry {
    /// List of all built-in dialect plugins.
    public static let allDialects: [any LogoParserPlugin] = [
        LogoTraditionalChinesePlugin()
    ]

    /// Finds a built-in dialect plugin matching the given ID or alias (case-insensitive).
    public static func dialect(for id: String) -> (any LogoParserPlugin)? {
        let cleanId = id.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return allDialects.first {
            $0.id.lowercased() == cleanId || $0.aliases.contains { $0.lowercased() == cleanId }
        }
    }
}
