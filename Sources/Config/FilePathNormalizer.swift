import Foundation

/// Cross-platform utility for normalizing file paths and `file://` URLs.
public enum FilePathNormalizer {
    /// Checks if a given string has a `file://` or `file:` URL scheme.
    public static func isFileURL(_ text: String) -> Bool {
        var trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix("<") && trimmed.hasSuffix(">") {
            trimmed = String(trimmed.dropFirst().dropLast()).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return trimmed.lowercased().hasPrefix("file://") || trimmed.lowercased().hasPrefix("file:")
    }

    /// Converts a file URL (or normal path) into a clean, unencoded local file path,
    /// stripping `file://` and percent-decoding encoded characters (e.g. `%20`, `%E4%B8%AD%E6%96%87`).
    public static func fileURLToPath(_ text: String) -> String {
        var str = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if str.hasPrefix("<") && str.hasSuffix(">") {
            str = String(str.dropFirst().dropLast()).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        guard isFileURL(str) else {
            return str
        }

        // Standardize file prefix
        let lower = str.lowercased()
        if lower.hasPrefix("file://localhost/") {
            str = String(str.dropFirst(16)) // keeps leading "/"
        } else if lower.hasPrefix("file://localhost") {
            str = String(str.dropFirst(16))
        } else if lower.hasPrefix("file:///") {
            str = String(str.dropFirst(7)) // keeps leading "/"
        } else if lower.hasPrefix("file://") {
            let withoutScheme = String(str.dropFirst(7))
            str = withoutScheme
        } else if lower.hasPrefix("file:") {
            str = String(str.dropFirst(5))
        }

        // Percent-decode URL characters
        if let decoded = str.removingPercentEncoding {
            str = decoded
        }

        // Handle Windows drive paths like `/C:/Users/...` -> `C:/Users/...`
        if str.count >= 3 && str.hasPrefix("/") {
            let secondIdx = str.index(after: str.startIndex)
            let thirdIdx = str.index(after: secondIdx)
            if str[secondIdx].isLetter && str[thirdIdx] == ":" {
                str = String(str.dropFirst())
            }
        }

        return str
    }

    /// Parses a path or file URL and extracts line and column anchors
    /// (e.g. `#L42`, `#L42C10`, `#L42:10`, `:42:10`, or `:42`).
    public static func parseLocation(from text: String) -> (filePath: String, line: Int?, column: Int?) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return ("", nil, nil)
        }

        var working = trimmed
        var targetLine: Int? = nil
        var targetCol: Int? = nil

        // 1. Check for URL fragment / anchor '#...'
        if let hashIdx = working.lastIndex(of: "#") {
            let anchorPart = String(working[working.index(after: hashIdx)...]).trimmingCharacters(in: .whitespacesAndNewlines)
            let pathPart = String(working[..<hashIdx])
            if let (line, col) = parseAnchorLineAndColumn(anchorPart) {
                targetLine = line
                targetCol = col
                working = pathPart
            }
        }

        // 2. Check for colon-separated line/column at the end (e.g. path.dart:123:45 or path.dart:123)
        // Ensure Windows drive letters (e.g. C:\... or C:/...) are not misparsed.
        if targetLine == nil {
            let (pathWithoutColon, line, col) = parseColonLineAndColumn(working)
            if let line = line {
                targetLine = line
                targetCol = col
                working = pathWithoutColon
            }
        }

        let resolvedPath = isFileURL(working) ? fileURLToPath(working) : working
        return (resolvedPath, targetLine, targetCol)
    }

    private static func parseAnchorLineAndColumn(_ anchor: String) -> (line: Int, column: Int?)? {
        var str = anchor
        if str.uppercased().hasPrefix("L") {
            str = String(str.dropFirst())
        }
        if str.contains("C") || str.contains("c") {
            let parts = str.components(separatedBy: CharacterSet(charactersIn: "Cc"))
            if parts.count >= 2, let l = Int(parts[0]), l > 0, let c = Int(parts[1]), c > 0 {
                return (l, c)
            }
        }
        if str.contains(":") {
            let parts = str.components(separatedBy: ":")
            if parts.count >= 2, let l = Int(parts[0]), l > 0, let c = Int(parts[1]), c > 0 {
                return (l, c)
            }
        }
        if let l = Int(str), l > 0 {
            return (l, nil)
        }
        return nil
    }

    private static func parseColonLineAndColumn(_ input: String) -> (cleanPath: String, line: Int?, column: Int?) {
        let parts = input.components(separatedBy: ":")
        if parts.count == 2 {
            if parts[0].count == 1, let firstChar = parts[0].first, firstChar.isLetter {
                // Windows drive letter like C:\foo
                return (input, nil, nil)
            }
            if let line = Int(parts[1]), line > 0 {
                return (parts[0], line, nil)
            }
        } else if parts.count >= 3 {
            // Check if last two parts are integers: path:line:col
            if let line = Int(parts[parts.count - 2]), line > 0,
               let col = Int(parts[parts.count - 1]), col > 0 {
                let cleanPath = parts[0..<(parts.count - 2)].joined(separator: ":")
                return (cleanPath, line, col)
            }
            // Check if last part is integer: path:line (e.g. C:/foo/bar.txt:123)
            if let line = Int(parts[parts.count - 1]), line > 0 {
                let cleanPath = parts[0..<(parts.count - 1)].joined(separator: ":")
                return (cleanPath, line, nil)
            }
        }
        return (input, nil, nil)
    }
}
