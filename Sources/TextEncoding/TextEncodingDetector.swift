import Foundation

extension String.Encoding {
    /// Big5 (Traditional Chinese) encoding
    public static let big5 = String.Encoding(rawValue: 0x8000_0A03)
    /// GB18030 (Simplified Chinese) encoding
    public static let gb18030 = String.Encoding(rawValue: 0x8000_0632)
    /// GBK (Simplified Chinese) encoding
    public static let gbk = String.Encoding(rawValue: 0x8000_0421)
    /// Shift-JIS (Japanese) encoding
    public static let shiftJISCustom = String.Encoding(rawValue: 0x8000_0A01)
    /// EUC-JP (Japanese) encoding
    public static let eucJPCustom = String.Encoding(rawValue: 0x8000_0920)
}

public enum TextEncodingDetector {
    /// Detects character encoding from raw byte data and decodes it into String.
    public static func detectAndDecode(_ data: Data) -> TextReadResult? {
        if data.isEmpty {
            return TextReadResult(content: "", encoding: .utf8)
        }

        // 1. Check Byte Order Mark (BOM)
        if let bomResult = detectBOM(data) {
            return bomResult
        }

        // 2. Strict UTF-8 validation (without BOM)
        if let utf8Result = tryDecode(data, encoding: .utf8) {
            return utf8Result
        }

        #if !os(WASI)
            // 3. Multi-byte candidate encodings
            let candidateEncodings: [String.Encoding] = [
                .big5,
                .gb18030,
                .gbk,
                .shiftJISCustom,
                .utf16,
                .eucJPCustom,
            ]

            for encoding in candidateEncodings {
                if let decodedResult = tryDecode(data, encoding: encoding) {
                    return decodedResult
                }
            }

            // 4. Single-byte 8-bit fallback (e.g. Windows-1252 / ISO-8859-1)
            if let fallbackString = String(data: data, encoding: .windowsCP1252)
                ?? String(data: data, encoding: .isoLatin1)
            {
                let actualEncoding: String.Encoding =
                    String(data: data, encoding: .windowsCP1252) != nil ? .windowsCP1252 : .isoLatin1
                return TextReadResult(content: fallbackString, encoding: actualEncoding)
            }
            return nil
        #else
            // Safe fallback for WebAssembly / WASI runtime without legacy encoding tables
            return TextReadResult(content: String(decoding: data, as: UTF8.self), encoding: .utf8)
        #endif
    }

    private static func tryDecode(_ data: Data, encoding: String.Encoding) -> TextReadResult? {
        if let decoded = String(data: data, encoding: encoding) {
            return TextReadResult(content: decoded, encoding: encoding)
        }
        // If data is truncated at a sample boundary (e.g. 8192 bytes), try trimming 1..3 trailing bytes
        if data.count >= 4 {
            for trim in 1...3 {
                let trimmedData = data.dropLast(trim)
                if let decoded = String(data: trimmedData, encoding: encoding) {
                    return TextReadResult(content: decoded, encoding: encoding)
                }
            }
        }
        return nil
    }

    private static func detectBOM(_ data: Data) -> TextReadResult? {
        let bytes = [UInt8](data.prefix(4))

        // UTF-8 BOM: EF BB BF
        if bytes.count >= 3 && bytes[0] == 0xEF && bytes[1] == 0xBB && bytes[2] == 0xBF {
            let contentData = data.dropFirst(3)
            if let content = String(data: contentData, encoding: .utf8) {
                return TextReadResult(content: content, encoding: .utf8)
            }
        }

        // UTF-16 LE BOM: FF FE
        if bytes.count >= 2 && bytes[0] == 0xFF && bytes[1] == 0xFE {
            if bytes.count < 4 || !(bytes[2] == 0x00 && bytes[3] == 0x00) {
                let contentData = data.dropFirst(2)
                if let content = String(data: contentData, encoding: .utf16LittleEndian) {
                    return TextReadResult(content: content, encoding: .utf16LittleEndian)
                }
            }
        }

        // UTF-16 BE BOM: FE FF
        if bytes.count >= 2 && bytes[0] == 0xFE && bytes[1] == 0xFF {
            let contentData = data.dropFirst(2)
            if let content = String(data: contentData, encoding: .utf16BigEndian) {
                return TextReadResult(content: content, encoding: .utf16BigEndian)
            }
        }

        // UTF-32 LE BOM: FF FE 00 00
        if bytes.count >= 4 && bytes[0] == 0xFF && bytes[1] == 0xFE && bytes[2] == 0x00 && bytes[3] == 0x00 {
            let contentData = data.dropFirst(4)
            if let content = String(data: contentData, encoding: .utf32LittleEndian) {
                return TextReadResult(content: content, encoding: .utf32LittleEndian)
            }
        }

        // UTF-32 BE BOM: 00 00 FE FF
        if bytes.count >= 4 && bytes[0] == 0x00 && bytes[1] == 0x00 && bytes[2] == 0xFE && bytes[3] == 0xFF {
            let contentData = data.dropFirst(4)
            if let content = String(data: contentData, encoding: .utf32BigEndian) {
                return TextReadResult(content: content, encoding: .utf32BigEndian)
            }
        }

        return nil
    }

    /// User-friendly display name for a given String.Encoding.
    public static func displayName(for encoding: String.Encoding) -> String {
        switch encoding {
        case .utf8:
            "UTF-8"
        case .utf16, .utf16BigEndian, .utf16LittleEndian:
            "UTF-16"
        case .utf32, .utf32BigEndian, .utf32LittleEndian:
            "UTF-32"
        case .big5:
            "Big5"
        case .gb18030, .gbk:
            "GB18030"
        case .shiftJISCustom:
            "Shift-JIS"
        case .eucJPCustom:
            "EUC-JP"
        case .windowsCP1252:
            "Windows-1252"
        case .isoLatin1:
            "ISO-8859-1"
        default:
            "Encoding (\(encoding.rawValue))"
        }
    }
}
