import Foundation

/// Fields supported when formatting person names via dictionaries or option lists.
public enum LogoPersonNameField: String, CaseIterable, Sendable, Equatable {
    case givenName
    case familyName
    case middleName
    case prefix
    case suffix
    case nickname
    case fullName
    case style
    case locale

    public static func parse(_ raw: String) -> LogoPersonNameField? {
        let clean = raw.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: ":\"' ")).trimmingCharacters(
            in: .whitespacesAndNewlines)
        switch clean {
        case "given", "first", "firstname", "givenname": return .givenName
        case "family", "last", "lastname", "familyname", "surname": return .familyName
        case "middle", "middlename": return .middleName
        case "prefix", "title": return .prefix
        case "suffix": return .suffix
        case "nickname", "nick": return .nickname
        case "name", "full", "fullname": return .fullName
        case "style": return .style
        case "locale", "loc", "lang": return .locale
        default: return nil
        }
    }
}
