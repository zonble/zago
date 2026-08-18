import Foundation

/// Line ending convention for a text document.
public enum LineEnding: String, Sendable, CaseIterable {
    case lf = "unix"
    case crlf = "dos"
    case cr = "mac"

    public var separator: String {
        switch self {
        case .lf: return "\n"
        case .crlf: return "\r\n"
        case .cr: return "\r"
        }
    }

    public var displayName: String {
        switch self {
        case .lf: return "Unix (LF)"
        case .crlf: return "DOS (CRLF)"
        case .cr: return "Mac (CR)"
        }
    }

    public var statusTag: String? {
        switch self {
        case .lf: return nil
        case .crlf: return "[DOS Format]"
        case .cr: return "[Mac Format]"
        }
    }

    /// Detects line ending convention from raw text content using dominant frequency (majority vote).
    public static func detect(in text: String, fallback: LineEnding = .lf) -> LineEnding {
        var crlfCount = 0
        var lfCount = 0
        var crCount = 0

        var prevWasCR = false
        for scalar in text.unicodeScalars {
            if scalar.value == 0x0D {  // \r
                if prevWasCR {
                    crCount += 1
                }
                prevWasCR = true
            } else if scalar.value == 0x0A {  // \n
                if prevWasCR {
                    crlfCount += 1
                    prevWasCR = false
                } else {
                    lfCount += 1
                }
            } else {
                if prevWasCR {
                    crCount += 1
                    prevWasCR = false
                }
            }
        }
        if prevWasCR {
            crCount += 1
        }

        if crlfCount == 0 && lfCount == 0 && crCount == 0 {
            return fallback
        }
        if crlfCount >= lfCount && crlfCount >= crCount {
            return .crlf
        }
        if lfCount >= crlfCount && lfCount >= crCount {
            return .lf
        }
        return .cr
    }
}
