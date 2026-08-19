import Foundation

/// Pure Swift, zero-dependency data encoding, decoding, and cryptographic hashing utilities for LOGO Engine.
public enum LogoDataCodec {

    // MARK: - Base64 Encoding & Decoding

    /// Encodes a UTF-8 string to Base64.
    public static func base64Encode(_ string: String) -> String {
        Data(string.utf8).base64EncodedString()
    }

    /// Decodes a Base64 string to a UTF-8 string. Returns nil if decoding or UTF-8 conversion fails.
    public static func base64Decode(_ string: String) -> String? {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let data = Data(base64Encoded: trimmed) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    /// Checks whether a string is valid Base64 format.
    public static func isValidBase64(_ string: String) -> Bool {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed.count % 4 == 0 else { return false }
        return Data(base64Encoded: trimmed) != nil
    }

    // MARK: - URL Percent Encoding & Decoding

    /// URL percent-encodes a string using URL query allowed characters.
    public static func urlEncode(_ string: String) -> String {
        string.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? string
    }

    /// URL percent-decodes a string.
    public static func urlDecode(_ string: String) -> String {
        string.removingPercentEncoding ?? string
    }

    // MARK: - Hex Encoding & Decoding

    /// Encodes an integer to `"0xXXXX"` or UTF-8 text string to lowercase hex bytes.
    public static func hexEncode(_ input: String) -> String {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        if let intVal = Int(trimmed) {
            if intVal < 0 {
                return String(format: "-0x%X", abs(intVal))
            } else {
                return String(format: "0x%X", intVal)
            }
        }
        return input.utf8.map { String(format: "%02x", $0) }.joined()
    }

    /// Decodes `"0xXXXX"` to decimal integer string, or hex byte string to UTF-8 text.
    public static func hexDecode(_ input: String) -> String? {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }

        if trimmed.hasPrefix("0x") || trimmed.hasPrefix("0X") {
            let hexDigits = String(trimmed.dropFirst(2))
            guard let val = Int(hexDigits, radix: 16) else { return nil }
            return String(val)
        }

        if trimmed.hasPrefix("-0x") || trimmed.hasPrefix("-0X") {
            let hexDigits = String(trimmed.dropFirst(3))
            guard let val = Int(hexDigits, radix: 16) else { return nil }
            return String(-val)
        }

        // Parse hex byte string (e.g. "68656c6c6f" -> "hello")
        guard trimmed.count % 2 == 0 else { return nil }
        var bytes: [UInt8] = []
        bytes.reserveCapacity(trimmed.count / 2)

        var idx = trimmed.startIndex
        while idx < trimmed.endIndex {
            let nextIdx = trimmed.index(idx, offsetBy: 2)
            let chunk = String(trimmed[idx..<nextIdx])
            guard let byte = UInt8(chunk, radix: 16) else { return nil }
            bytes.append(byte)
            idx = nextIdx
        }

        return String(bytes: bytes, encoding: .utf8)
    }

    // MARK: - SHA-256 Hash (FIPS 180-4)

    /// Computes the 64-character lowercase SHA-256 hex digest of a string.
    public static func sha256(_ string: String) -> String {
        let data = Array(string.utf8)
        let hash = sha256Bytes(data)
        return hash.map { String(format: "%02x", $0) }.joined()
    }

    private static func sha256Bytes(_ message: [UInt8]) -> [UInt8] {
        var h: [UInt32] = [
            0x6a09_e667, 0xbb67_ae85, 0x3c6e_f372, 0xa54f_f53a,
            0x510e_527f, 0x9b05_688c, 0x1f83_d9ab, 0x5be0_cd19,
        ]

        let k: [UInt32] = [
            0x428a_2f98, 0x7137_4491, 0xb5c0_fbcf, 0xe9b5_dba5, 0x3956_c25b, 0x59f1_11f1, 0x923f_82a4, 0xab1c_5ed5,
            0xd807_aa98, 0x1283_5b01, 0x2431_85be, 0x550c_7dc3, 0x72be_5d74, 0x80de_b1fe, 0x9bdc_06a7, 0xc19b_f174,
            0xe49b_69c1, 0xefbe_4786, 0x0fc1_9dc6, 0x240c_a1cc, 0x2de9_2c6f, 0x4a74_84aa, 0x5cb0_a9dc, 0x76f9_88da,
            0x983e_5152, 0xa831_c66d, 0xb003_27c8, 0xbf59_7fc7, 0xc6e0_0bf3, 0xd5a7_9147, 0x06ca_6351, 0x1429_2967,
            0x27b7_0a85, 0x2e1b_2138, 0x4d2c_6dfc, 0x5338_0d13, 0x650a_7354, 0x766a_0abb, 0x81c2_c92e, 0x9272_2c85,
            0xa2bf_e8a1, 0xa81a_664b, 0xc24b_8b70, 0xc76c_51a3, 0xd192_e819, 0xd699_0624, 0xf40e_3585, 0x106a_a070,
            0x19a4_c116, 0x1e37_6c08, 0x2748_774c, 0x34b0_bcb5, 0x391c_0cb3, 0x4ed8_aa4a, 0x5b9c_ca4f, 0x682e_6ff3,
            0x748f_82ee, 0x78a5_636f, 0x84c8_7814, 0x8cc7_0208, 0x90be_fffa, 0xa450_6ceb, 0xbef9_a3f7, 0xc671_78f2,
        ]

        var data = message
        let bitLength = UInt64(data.count) * 8

        data.append(0x80)
        while (data.count % 64) != 56 {
            data.append(0x00)
        }

        for i in (0..<8).reversed() {
            data.append(UInt8((bitLength >> (i * 8)) & 0xFF))
        }

        for chunkStart in stride(from: 0, to: data.count, by: 64) {
            var w = [UInt32](repeating: 0, count: 64)
            for i in 0..<16 {
                let offset = chunkStart + i * 4
                w[i] =
                    (UInt32(data[offset]) << 24)
                    | (UInt32(data[offset + 1]) << 16)
                    | (UInt32(data[offset + 2]) << 8)
                    | UInt32(data[offset + 3])
            }

            for i in 16..<64 {
                let s0 = (w[i - 15] &>>> 7) ^ (w[i - 15] &>>> 18) ^ (w[i - 15] >> 3)
                let s1 = (w[i - 2] &>>> 17) ^ (w[i - 2] &>>> 19) ^ (w[i - 2] >> 10)
                w[i] = w[i - 16] &+ s0 &+ w[i - 7] &+ s1
            }

            var a = h[0]
            var b = h[1]
            var c = h[2]
            var d = h[3]
            var e = h[4]
            var f = h[5]
            var g = h[6]
            var hVal = h[7]

            for i in 0..<64 {
                let s1 = (e &>>> 6) ^ (e &>>> 11) ^ (e &>>> 25)
                let ch = (e & f) ^ ((~e) & g)
                let temp1 = hVal &+ s1 &+ ch &+ k[i] &+ w[i]
                let s0 = (a &>>> 2) ^ (a &>>> 13) ^ (a &>>> 22)
                let maj = (a & b) ^ (a & c) ^ (b & c)
                let temp2 = s0 &+ maj

                hVal = g
                g = f
                f = e
                e = d &+ temp1
                d = c
                c = b
                b = a
                a = temp1 &+ temp2
            }

            h[0] = h[0] &+ a
            h[1] = h[1] &+ b
            h[2] = h[2] &+ c
            h[3] = h[3] &+ d
            h[4] = h[4] &+ e
            h[5] = h[5] &+ f
            h[6] = h[6] &+ g
            h[7] = h[7] &+ hVal
        }

        var result: [UInt8] = []
        for word in h {
            result.append(UInt8((word >> 24) & 0xFF))
            result.append(UInt8((word >> 16) & 0xFF))
            result.append(UInt8((word >> 8) & 0xFF))
            result.append(UInt8(word & 0xFF))
        }
        return result
    }

    // MARK: - SHA-1 Hash (FIPS 180-1)

    /// Computes the 40-character lowercase SHA-1 hex digest of a string.
    public static func sha1(_ string: String) -> String {
        let data = Array(string.utf8)
        let hash = sha1Bytes(data)
        return hash.map { String(format: "%02x", $0) }.joined()
    }

    private static func sha1Bytes(_ message: [UInt8]) -> [UInt8] {
        var h: [UInt32] = [
            0x6745_2301, 0xefcd_ab89, 0x98ba_dcfe, 0x1032_5476, 0xc3d2_e1f0,
        ]

        var data = message
        let bitLength = UInt64(data.count) * 8

        data.append(0x80)
        while (data.count % 64) != 56 {
            data.append(0x00)
        }

        for i in (0..<8).reversed() {
            data.append(UInt8((bitLength >> (i * 8)) & 0xFF))
        }

        for chunkStart in stride(from: 0, to: data.count, by: 64) {
            var w = [UInt32](repeating: 0, count: 80)
            for i in 0..<16 {
                let offset = chunkStart + i * 4
                w[i] =
                    (UInt32(data[offset]) << 24)
                    | (UInt32(data[offset + 1]) << 16)
                    | (UInt32(data[offset + 2]) << 8)
                    | UInt32(data[offset + 3])
            }
            for i in 16..<80 {
                w[i] = (w[i - 3] ^ w[i - 8] ^ w[i - 14] ^ w[i - 16]) &<<< 1
            }

            var a = h[0]
            var b = h[1]
            var c = h[2]
            var d = h[3]
            var e = h[4]

            for i in 0..<80 {
                let f: UInt32
                let k: UInt32
                if i < 20 {
                    f = (b & c) | ((~b) & d)
                    k = 0x5a82_7999
                } else if i < 40 {
                    f = b ^ c ^ d
                    k = 0x6ed9_eba1
                } else if i < 60 {
                    f = (b & c) | (b & d) | (c & d)
                    k = 0x8f1b_bcdc
                } else {
                    f = b ^ c ^ d
                    k = 0xca62_c1d6
                }

                let temp = (a &<<< 5) &+ f &+ e &+ k &+ w[i]
                e = d
                d = c
                c = b &<<< 30
                b = a
                a = temp
            }

            h[0] = h[0] &+ a
            h[1] = h[1] &+ b
            h[2] = h[2] &+ c
            h[3] = h[3] &+ d
            h[4] = h[4] &+ e
        }

        var result: [UInt8] = []
        for word in h {
            result.append(UInt8((word >> 24) & 0xFF))
            result.append(UInt8((word >> 16) & 0xFF))
            result.append(UInt8((word >> 8) & 0xFF))
            result.append(UInt8(word & 0xFF))
        }
        return result
    }

    // MARK: - MD5 Hash (RFC 1321)

    /// Computes the 32-character lowercase MD5 hex digest of a string.
    public static func md5(_ string: String) -> String {
        let data = Array(string.utf8)
        let hash = md5Bytes(data)
        return hash.map { String(format: "%02x", $0) }.joined()
    }

    private static func md5Bytes(_ message: [UInt8]) -> [UInt8] {
        let s: [UInt32] = [
            7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22,
            5, 9, 14, 20, 5, 9, 14, 20, 5, 9, 14, 20, 5, 9, 14, 20,
            4, 11, 16, 23, 4, 11, 16, 23, 4, 11, 16, 23, 4, 11, 16, 23,
            6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15, 21,
        ]

        let k: [UInt32] = [
            0xd76a_a478, 0xe8c7_b756, 0x2420_70db, 0xc1bd_ceee,
            0xf57c_0faf, 0x4787_c62a, 0xa830_4613, 0xfd46_9501,
            0x6980_98d8, 0x8b44_f7af, 0xffff_5bb1, 0x895c_d7be,
            0x6b90_1122, 0xfd98_7193, 0xa679_438e, 0x49b4_0821,
            0xf61e_2562, 0xc040_b340, 0x265e_5a51, 0xe9b6_c7aa,
            0xd62f_105d, 0x0244_1453, 0xd8a1_e681, 0xe7d3_fbc8,
            0x21e1_cde6, 0xc337_07d6, 0xf4d5_0d87, 0x455a_14ed,
            0xa9e3_e905, 0xfcef_a3f8, 0x676f_02d9, 0x8d2a_4c8a,
            0xfffa_3942, 0x8771_f681, 0x6d9d_6122, 0xfde5_380c,
            0xa4be_ea44, 0x4bde_cfa9, 0xf6bb_4b60, 0xbebf_bc70,
            0x289b_7ec6, 0xeaa1_27fa, 0xd4ef_3085, 0x0488_1d05,
            0xd9d4_d039, 0xe6db_99e5, 0x1fa2_7cf8, 0xc4ac_5665,
            0xf429_2244, 0x432a_ff97, 0xab94_23a7, 0xfc93_a039,
            0x655b_59c3, 0x8f0c_cc92, 0xffef_f47d, 0x8584_5dd1,
            0x6fa8_7e4f, 0xfe2c_e6e0, 0xa301_4314, 0x4e08_11a1,
            0xf753_7e82, 0xbd3a_f235, 0x2ad7_d2bb, 0xeb86_d391,
        ]

        var a0: UInt32 = 0x6745_2301
        var b0: UInt32 = 0xefcd_ab89
        var c0: UInt32 = 0x98ba_dcfe
        var d0: UInt32 = 0x1032_5476

        var data = message
        let bitLength = UInt64(data.count) * 8

        data.append(0x80)
        while (data.count % 64) != 56 {
            data.append(0x00)
        }

        for i in 0..<8 {
            data.append(UInt8((bitLength >> (i * 8)) & 0xFF))
        }

        for chunkStart in stride(from: 0, to: data.count, by: 64) {
            var m = [UInt32](repeating: 0, count: 16)
            for i in 0..<16 {
                let offset = chunkStart + i * 4
                m[i] =
                    UInt32(data[offset])
                    | (UInt32(data[offset + 1]) << 8)
                    | (UInt32(data[offset + 2]) << 16)
                    | (UInt32(data[offset + 3]) << 24)
            }

            var a = a0
            var b = b0
            var c = c0
            var d = d0

            for i in 0..<64 {
                var f: UInt32 = 0
                var g: Int = 0
                if i < 16 {
                    f = (b & c) | ((~b) & d)
                    g = i
                } else if i < 32 {
                    f = (d & b) | ((~d) & c)
                    g = (5 * i + 1) % 16
                } else if i < 48 {
                    f = b ^ c ^ d
                    g = (3 * i + 5) % 16
                } else {
                    f = c ^ (b | (~d))
                    g = (7 * i) % 16
                }

                let temp = d
                d = c
                c = b
                b = b &+ ((a &+ f &+ k[i] &+ m[g]) &<<< s[i])
                a = temp
            }

            a0 = a0 &+ a
            b0 = b0 &+ b
            c0 = c0 &+ c
            d0 = d0 &+ d
        }

        var result: [UInt8] = []
        for word in [a0, b0, c0, d0] {
            result.append(UInt8(word & 0xFF))
            result.append(UInt8((word >> 8) & 0xFF))
            result.append(UInt8((word >> 16) & 0xFF))
            result.append(UInt8((word >> 24) & 0xFF))
        }
        return result
    }
}

// MARK: - Bitwise Rotate Helpers

extension UInt32 {
    fileprivate func rotateLeft(_ n: UInt32) -> UInt32 {
        (self << n) | (self >> (32 - n))
    }

    fileprivate func rotateRight(_ n: UInt32) -> UInt32 {
        (self >> n) | (self << (32 - n))
    }
}

infix operator &<<< : BitwiseShiftPrecedence
private func &<<< (lhs: UInt32, rhs: UInt32) -> UInt32 {
    lhs.rotateLeft(rhs)
}

infix operator &>>> : BitwiseShiftPrecedence
private func &>>> (lhs: UInt32, rhs: UInt32) -> UInt32 {
    lhs.rotateRight(rhs)
}
