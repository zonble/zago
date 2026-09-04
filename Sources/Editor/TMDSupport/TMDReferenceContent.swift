import Foundation

/// Content provider for TMD Quick Reference dialog.
public enum TMDReferenceContent {
    public static func lines(language: Language = .detectSystemLanguage()) -> [String] {
        L10n.string("tmdref.content", language: language).components(separatedBy: "\n")
    }
}
