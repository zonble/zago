import Foundation

enum LogoReferenceContent {
    static func lines(language: Language = .detectSystemLanguage()) -> [String] {
        L10n.string("logoref.content", language: language).components(separatedBy: "\n")
    }
}
