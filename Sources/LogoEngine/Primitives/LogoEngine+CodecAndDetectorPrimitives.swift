import Foundation

extension LogoEngine {
    /// Codec & Detector Primitives Evaluator (`evaluateCodecAndDetectorPrimitives`)
    ///
    /// Evaluates Data Detectors, UUID generation, Base64/Hex/URL encoding, and Hashes.
    internal func evaluateCodecAndDetectorPrimitives(_ tokens: [String], index: inout Int) -> String? {
        guard index < tokens.count, let prim = parsePrimitive(tokens[index]) else { return nil }

        switch prim {
        case .detectURL, .detectEmail, .detectPhone, .detectDate, .detectAddress:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let text = unquote(reader.nextExpression())
            reader.commit(to: &index)
            return evaluateDetectPrimitive(prim, text: text)

        case .uuid:
            return evaluateUUIDPrimitive(tokens: tokens, index: &index)

        case .isUUID:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let input = unquote(reader.nextExpression())
            reader.commit(to: &index)
            let valid = LogoUUIDGenerator.isValidUUID(input)
            setLastExpressionBoolean(valid)
            return valid.logoString

        case .uuidTime:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let input = unquote(reader.nextExpression())
            reader.commit(to: &index)
            guard let date = LogoUUIDGenerator.extractV7Date(from: input) else {
                let msg = "[LOGO Error: UUID '\(input)' is not a valid UUID v7 with extractable timestamp]"
                reportError(LogoError(code: 1, message: msg), token: "UUID.TIME")
                return ""
            }
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            let dateStr = formatter.string(from: date)
            setLastExpressionString(dateStr)
            return dateStr

        case .base64Encode:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let input = unquote(reader.nextExpression())
            reader.commit(to: &index)
            let encoded = LogoDataCodec.base64Encode(input)
            setLastExpressionString(encoded)
            return encoded

        case .base64Decode:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let input = unquote(reader.nextExpression())
            reader.commit(to: &index)
            guard let decoded = LogoDataCodec.base64Decode(input) else {
                let msg = "[LOGO Error: Invalid Base64 input string '\(input)']"
                reportError(LogoError(code: 1, message: msg), token: "BASE64.DECODE")
                return ""
            }
            setLastExpressionString(decoded)
            return decoded

        case .isBase64:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let input = unquote(reader.nextExpression())
            reader.commit(to: &index)
            let valid = LogoDataCodec.isValidBase64(input)
            setLastExpressionBoolean(valid)
            return valid.logoString

        case .urlEncode:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let input = unquote(reader.nextExpression())
            reader.commit(to: &index)
            let encoded = LogoDataCodec.urlEncode(input)
            setLastExpressionString(encoded)
            return encoded

        case .urlDecode:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let input = unquote(reader.nextExpression())
            reader.commit(to: &index)
            let decoded = LogoDataCodec.urlDecode(input)
            setLastExpressionString(decoded)
            return decoded

        case .hexEncode:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let input = unquote(reader.nextExpression())
            reader.commit(to: &index)
            let encoded = LogoDataCodec.hexEncode(input)
            setLastExpressionString(encoded)
            return encoded

        case .hexDecode:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let input = unquote(reader.nextExpression())
            reader.commit(to: &index)
            guard let decoded = LogoDataCodec.hexDecode(input) else {
                let msg = "[LOGO Error: Invalid Hex input string '\(input)']"
                reportError(LogoError(code: 1, message: msg), token: "HEX.DECODE")
                return ""
            }
            setLastExpressionString(decoded)
            return decoded

        case .hashSha256:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let input = unquote(reader.nextExpression())
            reader.commit(to: &index)
            let hash = LogoDataCodec.sha256(input)
            setLastExpressionString(hash)
            return hash

        case .hashSha1:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let input = unquote(reader.nextExpression())
            reader.commit(to: &index)
            let hash = LogoDataCodec.sha1(input)
            setLastExpressionString(hash)
            return hash

        case .hashMd5:
            var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
            let input = unquote(reader.nextExpression())
            reader.commit(to: &index)
            let hash = LogoDataCodec.md5(input)
            setLastExpressionString(hash)
            return hash

        default:
            return nil
        }
    }

    internal func evaluateDetectPrimitive(_ primitive: LogoPrimitive, text: String) -> String {
        #if !canImport(Darwin)
            let name = primitive.meta.name
            let message = "[LOGO Error: \(name) is not supported on this platform]"
            reportError(LogoError(code: 1, message: message), token: name)
            return ""
        #else
            guard let kind = LogoDetectorKind(primitive) else { return "" }
            let matches = LogoDetectors.detect(text, kind: kind)
            let result = LogoValue.list(matches.map(LogoValue.string)).description
            setLastExpressionString(result)
            return result
        #endif
    }

    private func evaluateUUIDPrimitive(tokens: [String], index: inout Int) -> String {
        var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
        var flavor = "v4"
        if let arg = reader.nextOptionalExpression(isBoundary: { [weak self] in (self?.isKeyword($0) ?? LogoEngine.isKeyword($0)) || $0 == "]" || $0 == ")" }) {
            flavor = unquote(arg)
        }
        reader.commit(to: &index)
        let generated = LogoUUIDGenerator.generate(flavor: flavor)
        setLastExpressionString(generated)
        return generated
    }
}
