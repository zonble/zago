import Foundation

internal enum LogoDetectorKind {
    case url
    case email
    case phone
    case date
    case address

    init?(_ primitive: LogoPrimitive) {
        switch primitive {
        case .detectURL: self = .url
        case .detectEmail: self = .email
        case .detectPhone: self = .phone
        case .detectDate: self = .date
        case .detectAddress: self = .address
        default: return nil
        }
    }

    init?(raw: String) {
        let clean = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let stripped = clean.hasPrefix(":") ? String(clean.dropFirst()) : clean
        switch stripped {
        case "url", "link": self = .url
        case "email", "mail": self = .email
        case "phone", "tel": self = .phone
        case "date", "time": self = .date
        case "address", "addr": self = .address
        default: return nil
        }
    }
}

internal enum LogoDetectors {
    static func detect(_ text: String, kind: LogoDetectorKind) -> [String] {
        #if os(Linux) || os(Windows)
            return []
        #else
            let types: NSTextCheckingResult.CheckingType = [.link, .phoneNumber, .date, .address]
            guard let detector = try? NSDataDetector(types: types.rawValue) else { return [] }
            let range = NSRange(text.startIndex..<text.endIndex, in: text)

            return detector.matches(in: text, options: [], range: range).compactMap { result in
                let value = (text as NSString).substring(with: result.range)
                switch kind {
                case .url:
                    guard result.resultType == .link, result.url?.scheme?.lowercased() != "mailto" else { return nil }
                case .email:
                    guard result.resultType == .link else { return nil }
                    let isMailto = result.url?.scheme?.lowercased() == "mailto"
                    guard isMailto || value.contains("@") else { return nil }
                case .phone:
                    guard result.resultType == .phoneNumber else { return nil }
                case .date:
                    guard result.resultType == .date else { return nil }
                case .address:
                    guard result.resultType == .address else { return nil }
                }
                return value
            }
        #endif
    }
}
