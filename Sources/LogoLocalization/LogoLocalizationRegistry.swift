import Foundation
import LogoEngine

/// Central factory for discovering and instantiating built-in localized Logo plugins / dialects.
public enum LogoLocalizationRegistry {
    /// List of all built-in dialect plugins.
    public static let allDialects: [any LogoParserPlugin] = [
        LogoTraditionalChinesePlugin(),
        LogoEmojiPlugin(),
    ]

    /// Finds a built-in dialect plugin matching the given ID or alias (case-insensitive).
    public static func dialect(for id: String) -> (any LogoParserPlugin)? {
        let cleanId = id.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return allDialects.first {
            $0.id.lowercased() == cleanId || $0.aliases.contains { $0.lowercased() == cleanId }
        }
    }

    /// Parses a token into a `LogoPrimitive` using all registered built-in dialects.
    public static func parsePrimitive(_ token: String) -> LogoPrimitive? {
        for dialect in allDialects {
            if let prim = dialect.parsePrimitive(token) {
                return prim
            }
        }
        return nil
    }

    /// Returns all localized aliases for the given primitive across all built-in dialects.
    public static func aliases(for primitive: LogoPrimitive) -> [String] {
        allDialects.flatMap { $0.aliases(for: primitive) }
    }

    /// All keyword aliases from all built-in dialects.
    public static var allKeywordAliases: [String] {
        allDialects.flatMap(\.keywordAliases)
    }

    /// All filler tokens from all built-in dialects.
    public static var allFillerTokens: Set<String> {
        allDialects.reduce(into: Set<String>()) { $0.formUnion($1.fillerTokens) }
    }
}
