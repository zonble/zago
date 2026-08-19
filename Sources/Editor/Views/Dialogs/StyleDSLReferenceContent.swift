import Foundation

enum StyleDSLReferenceContent {
    static func lines(language: Language = .detectSystemLanguage()) -> [String] {
        L10n.string("styledsl.content", language: language).components(separatedBy: "\n")
    }
}
