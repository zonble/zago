import Foundation

/// Advanced Foundation-powered Person Name formatter for LogoEngine.
public enum LogoPersonNameFormatter {
    public static func disambiguateOptions(
        _ args: [String],
        style: inout LogoPersonNameStyle,
        locale: inout String?
    ) {
        for arg in args {
            let clean = arg.trimmingCharacters(in: CharacterSet(charactersIn: "\"':; ")).trimmingCharacters(
                in: .whitespacesAndNewlines)
            if clean.isEmpty { continue }
            let lower = clean.hasPrefix(":") ? String(clean.dropFirst()).lowercased() : clean.lowercased()

            if LogoPersonNameStyle.isStyleKeyword(lower) {
                style = LogoPersonNameStyle.parse(lower)
            } else {
                locale = clean
            }
        }
    }

    public static func format(
        givenName: String? = nil,
        familyName: String? = nil,
        middleName: String? = nil,
        prefix: String? = nil,
        suffix: String? = nil,
        nickname: String? = nil,
        fullName: String? = nil,
        style: LogoPersonNameStyle = .default,
        locale: String? = nil
    ) -> String {
        #if canImport(Darwin)
            var components = PersonNameComponents()
            if let given = givenName, !given.isEmpty { components.givenName = given }
            if let family = familyName, !family.isEmpty { components.familyName = family }
            if let middle = middleName, !middle.isEmpty { components.middleName = middle }
            if let pfx = prefix, !pfx.isEmpty { components.namePrefix = pfx }
            if let sfx = suffix, !sfx.isEmpty { components.nameSuffix = sfx }
            if let nick = nickname, !nick.isEmpty { components.nickname = nick }

            let targetLocale = LogoDateTimeFormatter.parseLocale(locale)
            let formatter = PersonNameComponentsFormatter()
            formatter.locale = targetLocale
            formatter.style = style.formatterStyle

            if let full = fullName, components.givenName == nil && components.familyName == nil {
                if let parsed = formatter.personNameComponents(from: full) {
                    return formatter.string(from: parsed)
                }
                return full
            }

            return formatter.string(from: components)
        #else
            return ""
        #endif
    }
}
