import Drawing
import Foundation

extension LogoEngine {
    public func register(plugin: any LogoParserPlugin) {
        pluginRegistry.register(plugin)
    }

    public func unregister(pluginId: String) {
        pluginRegistry.unregister(id: pluginId)
    }

    public func parsePrimitive(_ token: String) -> LogoPrimitive? {
        LogoPrimitive.from(token, registry: pluginRegistry)
    }

    public func parseOperator(_ token: String) -> LogoOperator? {
        LogoOperator.from(token, registry: pluginRegistry)
    }

    public func parseHeading(_ token: String) -> LogoHeading? {
        pluginRegistry.parseHeading(token) ?? LogoHeading(token)
    }

    public func parseBoolean(_ token: String) -> Bool? {
        switch token.lowercased() {
        case "true", "1":
            return true
        case "false", "0":
            return false
        default:
            return pluginRegistry.parseBoolean(token)
        }
    }

    public func parseBorderStyle(_ token: String) -> BorderStyle? {
        pluginRegistry.parseBorderStyle(token) ?? BorderStyle(token)
    }

    public func parseCalendarIdentifier(_ token: String) -> Calendar.Identifier? {
        pluginRegistry.parseCalendarIdentifier(token) ?? Calendar.Identifier(logoCalendarName: token)
    }

    public func parseDateTimeStylePreset(_ token: String, mode: LogoDateTimeMode = .dateTime) -> LogoDateTimeStylePreset? {
        pluginRegistry.parseDateTimeStylePreset(token) ?? (LogoDateTimeStylePreset.isPresetName(token) ? LogoDateTimeStylePreset(raw: token, mode: mode) : nil)
    }

    public func parseNumberStyle(_ token: String) -> LogoNumberStyle? {
        pluginRegistry.parseNumberStyle(token) ?? (LogoNumberStyle.isStyleKeyword(token) ? LogoNumberStyle.parse(token) : nil)
    }

    public func parseListType(_ token: String) -> LogoListType? {
        pluginRegistry.parseListType(token) ?? (LogoListType.isTypeKeyword(token) ? LogoListType.parse(token) : nil)
    }

    public func parseByteCountStyle(_ token: String) -> LogoByteCountStyle? {
        pluginRegistry.parseByteCountStyle(token) ?? (LogoByteCountStyle.isStyleKeyword(token) ? LogoByteCountStyle.parse(token) : nil)
    }

    public func parsePersonNameStyle(_ token: String) -> LogoPersonNameStyle? {
        pluginRegistry.parsePersonNameStyle(token) ?? (LogoPersonNameStyle.isStyleKeyword(token) ? LogoPersonNameStyle.parse(token) : nil)
    }

    public func parsePersonNameField(_ token: String) -> LogoPersonNameField? {
        pluginRegistry.parsePersonNameField(token) ?? LogoPersonNameField.parse(token)
    }

    public func parseFormatOptionField(_ token: String) -> LogoFormatOptionField? {
        pluginRegistry.parseFormatOptionField(token) ?? LogoFormatOptionField.parse(token)
    }

    public func parseExitPosition(_ token: String) -> BoxExitPosition? {
        pluginRegistry.parseExitPosition(token) ?? BoxExitPosition(token)
    }

    public static let standardFillerTokens: Set<String> = ["THEN"]
    public static let nonFillerPrefixes: [String] = ["\"", ":", "[", "("]

    public func isFillerToken(_ token: String) -> Bool {
        guard !Self.nonFillerPrefixes.contains(where: { token.hasPrefix($0) }) else { return false }
        return Self.standardFillerTokens.contains(token.uppercased()) || pluginRegistry.isFillerToken(token)
    }

    public func isKeyword(_ token: String) -> Bool {
        guard let prim = parsePrimitive(token) else { return false }
        return Self.keywords.contains(prim)
    }

    public func isStatementCommand(_ token: String) -> Bool {
        guard let prim = parsePrimitive(token) else { return false }
        return Self.statementCommands.contains(prim)
    }

    internal static func isKeyword(_ token: String) -> Bool {
        guard let prim = LogoPrimitive.from(token) else { return false }
        return keywords.contains(prim)
    }

    internal static func isStatementCommand(_ token: String) -> Bool {
        guard let prim = LogoPrimitive.from(token) else { return false }
        return statementCommands.contains(prim)
    }

    internal static func isVariadicPrimitive(_ prim: LogoPrimitive) -> Bool {
        return variadicPrimitives.contains(prim)
    }

    internal func optionalCommandArgument(_ tokens: [String], index: inout Int) -> String? {
        var reader = LogoArgumentReader(engine: self, tokens: tokens, index: index)
        guard
            let value = reader.nextOptionalExpression(isBoundary: { [weak self] token in
                (self?.isStatementCommand(token) ?? LogoEngine.isStatementCommand(token)) || token == "]" || token == ")"
            })
        else { return nil }
        reader.commit(to: &index)
        return unquote(value)
    }
}
