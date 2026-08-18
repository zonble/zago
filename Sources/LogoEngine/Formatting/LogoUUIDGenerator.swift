import Foundation

/// Fast, RFC-compliant UUID generation, validation, and metadata extraction for LOGO Engine.
public enum LogoUUIDGenerator {
    /// Generates a UUID string according to the requested flavor/version.
    /// - Parameters:
    ///   - flavor: `"v4"`, `"random"`, `"v7"`, `"time"`, `"nil"`, `"empty"`, `"short"`, `"nano"`. Defaults to `"v4"`.
    /// - Returns: A lowercase UUID or short unique ID string.
    public static func generate(flavor: String = "v4") -> String {
        let clean = flavor.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let stripped = clean.hasPrefix(":") ? String(clean.dropFirst()) : clean

        switch stripped {
        case "v7", "time", "timestamp":
            return generateV7()
        case "nil", "empty", "zero", "0":
            return "00000000-0000-0000-0000-000000000000"
        case "short", "nano", "nanoid", "compact":
            return generateShortID()
        case "v4", "random", "":
            return UUID().uuidString.lowercased()
        default:
            return UUID().uuidString.lowercased()
        }
    }

    /// Generates an RFC 9562 compliant UUID v7 with millisecond timestamp + random data.
    public static func generateV7(timestampMs: UInt64 = UInt64(Date().timeIntervalSince1970 * 1000.0)) -> String {
        let randomBytes = (0..<10).map { _ in UInt8.random(in: 0...255) }

        // UUID v7 layout:
        // 48-bit timestamp (ms) | 4-bit ver (0x7) | 12-bit rand_a | 2-bit var (0b10) | 62-bit rand_b
        let timeHigh = UInt32((timestampMs >> 16) & 0xFFFF_FFFF)
        let timeMid = UInt16(timestampMs & 0xFFFF)

        let verAndRandA = (UInt16(0x7) << 12) | (UInt16(randomBytes[0] & 0x0F) << 8) | UInt16(randomBytes[1])
        let varAndRandB = (UInt8(0b10) << 6) | (randomBytes[2] & 0x3F)

        return String(
            format: "%08x-%04x-%04x-%02x%02x-%02x%02x%02x%02x%02x%02x",
            timeHigh,
            timeMid,
            verAndRandA,
            varAndRandB,
            randomBytes[3],
            randomBytes[4],
            randomBytes[5],
            randomBytes[6],
            randomBytes[7],
            randomBytes[8],
            randomBytes[9]
        )
    }

    /// Generates an 8-character URL-safe alphanumeric identifier (Base62).
    public static func generateShortID(length: Int = 8) -> String {
        let alphabet = Array("0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ")
        return String((0..<length).compactMap { _ in alphabet.randomElement() })
    }

    /// Checks whether a given string is a valid UUID representation (32 hex chars with or without hyphens).
    public static func isValidUUID(_ string: String) -> Bool {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        return UUID(uuidString: trimmed) != nil
    }

    /// Extracts timestamp from UUID v7. Returns Date if valid v7 UUID, or nil.
    public static func extractV7Date(from uuidString: String) -> Date? {
        let trimmed = uuidString.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "-", with: "")
        guard trimmed.count == 32 else { return nil }

        // Check if version nibble is 7 (character index 12 in unhyphenated string)
        let chars = Array(trimmed)
        guard chars[12] == "7" else { return nil }

        // First 12 hex characters = 48-bit timestamp in milliseconds
        let timeHex = String(chars[0..<12])
        guard let timeMs = UInt64(timeHex, radix: 16) else { return nil }

        return Date(timeIntervalSince1970: Double(timeMs) / 1000.0)
    }
}
