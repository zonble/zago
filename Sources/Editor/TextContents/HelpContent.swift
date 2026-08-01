import Foundation

public enum HelpContent {
    private struct Section {
        let titleKey: String
        let itemPrefix: String
        let itemRange: ClosedRange<Int>
    }

    private static let divider = "  ================================================================"

    private static let sections: [Section] = [
        Section(titleKey: "helpview.sec_nav", itemPrefix: "helpview.nav", itemRange: 1...8),
        Section(titleKey: "helpview.sec_edit", itemPrefix: "helpview.edit", itemRange: 1...5),
        Section(titleKey: "helpview.sec_search", itemPrefix: "helpview.search", itemRange: 1...6),
        Section(titleKey: "helpview.sec_file", itemPrefix: "helpview.file", itemRange: 1...10),
        Section(titleKey: "helpview.sec_logo", itemPrefix: "helpview.logo", itemRange: 1...9),
    ]

    public static func lines(language: Language = L10n.currentLanguage) -> [String] {
        [L10n.string("helpview.header", language: language), divider] + sectionLines(language: language)
    }

    private static func sectionLines(language: Language) -> [String] {
        sections.enumerated().flatMap { index, section in
            let lines = [L10n.string(section.titleKey, language: language)]
                + section.itemRange.map { L10n.string("\(section.itemPrefix)_\($0)", language: language) }
            return index == sections.indices.last ? lines : lines + [""]
        }
    }
}
