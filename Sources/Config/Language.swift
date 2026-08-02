import Foundation

/// Supported language options for zago editor.
public enum Language: String, CaseIterable, Sendable {
    case en = "en"
    case zh_TW = "zh_TW"

    /// Detects current system language from LC_ALL, LC_MESSAGES, LANG, LANGUAGE, or Locale.
    public static func detectSystemLanguage() -> Language {
        let candidates = [
            ProcessInfo.processInfo.environment["LC_ALL"],
            ProcessInfo.processInfo.environment["LC_MESSAGES"],
            ProcessInfo.processInfo.environment["LANG"],
            ProcessInfo.processInfo.environment["LANGUAGE"],
            Locale.current.identifier
        ].compactMap { $0 }

        let keywords = ["zh", "tw", "hant", "hk"]
        for candidate in candidates {
            let lower = candidate.lowercased()
            if keywords.contains(where: { lower.contains($0) }) {
                return .zh_TW
            }
        }

        return .en
    }
}
