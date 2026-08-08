import Foundation
import LogoEngine

public enum LogoReferenceContent {
    public static func lines(language: Language = .detectSystemLanguage()) -> [String] {
        let contentLines = L10n.string("logoref.content", language: language).components(separatedBy: "\n")
        let headerText = L10n.string("logoref.all_aliases_header", language: language)
        let separatorLines = [
            "",
            "",
            "\(headerText)",
            "================================================================",
            ""
        ]
        return contentLines + separatorLines + wrappedAliases(width: 68)
    }

    private static func wrappedAliases(width: Int) -> [String] {
        var lines: [String] = []
        var current = "    "
        for alias in LogoPrimitive.keywordAliases {
            let item = current == "    " ? alias : ", \(alias)"
            if current.count + item.count > width {
                lines.append(current)
                current = "    \(alias)"
            } else {
                current += item
            }
        }
        if current != "    " {
            lines.append(current)
        }
        return lines
    }
}
