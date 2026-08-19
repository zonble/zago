import Foundation

/// Advanced Foundation-powered List formatter for LogoEngine.
public enum LogoListFormatter {
    public static func disambiguateOptions(
        _ args: [String],
        type: inout LogoListType,
        locale: inout String?
    ) {
        for arg in args {
            let clean = arg.trimmingCharacters(in: CharacterSet(charactersIn: "\"':; ")).trimmingCharacters(
                in: .whitespacesAndNewlines)
            if clean.isEmpty { continue }
            let lower = clean.hasPrefix(":") ? String(clean.dropFirst()).lowercased() : clean.lowercased()

            if LogoListType.isTypeKeyword(lower) {
                type = LogoListType.parse(lower)
            } else {
                locale = clean
            }
        }
    }

    public static func format(
        _ items: [String],
        type: LogoListType = .and,
        locale: String? = nil
    ) -> String {
        guard !items.isEmpty else { return "" }
        if items.count == 1 { return items[0] }

        #if os(Linux) || os(Windows)
            return ""
        #else
            let loc = LogoDateTimeFormatter.parseLocale(locale)
            let isChinese = loc.identifier.lowercased().hasPrefix("zh")

            switch type {
            case .and:
                let formatter = ListFormatter()
                formatter.locale = loc
                return formatter.string(from: items) ?? items.joined(separator: ", ")

            case .or:
                if isChinese {
                    if items.count == 2 {
                        return "\(items[0])或\(items[1])"
                    }
                    let head = items.dropLast().joined(separator: "、")
                    return "\(head)或\(items.last ?? "")"
                } else {
                    if items.count == 2 {
                        return "\(items[0]) or \(items[1])"
                    }
                    let head = items.dropLast().joined(separator: ", ")
                    return "\(head), or \(items.last ?? "")"
                }

            case .unit:
                if isChinese {
                    return items.joined(separator: "、")
                } else {
                    return items.joined(separator: ", ")
                }
            }
        #endif
    }
}
