import Foundation

extension LogoEngine {
    internal func setLastExpressionString(_ value: String) {
        lastExpressionValue = LogoValue.parse(value)
    }

    internal func setLastExpressionDateTime(_ value: String) {
        lastExpressionValue = .string(value)
    }

    internal func setLastExpressionBoolean(_ value: Bool) {
        lastExpressionValue = .string(value ? "true" : "false")
    }

    internal func setLastExpressionMeasurement(
        value: Double, unit: String, dimension: LogoMeasurementConverter.DimensionKind
    ) {
        lastExpressionValue = .measurement(value: value, unit: unit, dimension: dimension)
    }

    internal func normalizeVariableName(_ raw: String) -> String {
        var name = unquote(raw.trimmingCharacters(in: CharacterSet(charactersIn: "()")))
        if name.hasPrefix(":") {
            name.removeFirst()
        }
        return name.lowercased()
    }

    internal func parseLogoValuePreservingWhitespace(_ raw: String) -> LogoValue {
        LogoValue.parsePreservingWhitespace(raw)
    }
}
