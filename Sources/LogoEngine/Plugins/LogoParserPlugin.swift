import Drawing
import Foundation

/// Protocol for extensible language and dialect plugins in LOGO.
///
/// Plugins allow registering localized or domain-specific aliases for:
/// - Primitives (`LogoPrimitive`)
/// - Operators (`LogoOperator`)
/// - Headings (`LogoHeading`)
/// - Boolean literals (`Bool`)
/// - Domain options (border styles, exit positions, calendar identifiers, format options, etc.)
public protocol LogoParserPlugin: Sendable {
    /// Primary identifier for this dialect/plugin (e.g. "zh-TW", "zh-Hans", "ja").
    var id: String { get }

    /// Human-readable display name of the plugin (e.g. "Traditional Chinese (繁體中文)").
    var displayName: String { get }

    /// Alternative identifiers or aliases for this dialect (e.g. ["zh-Hant", "zh"]).
    var aliases: [String] { get }

    /// Parses a localized/custom token into a strongly-typed `LogoPrimitive`.
    func parsePrimitive(_ token: String) -> LogoPrimitive?

    /// Parses a localized/custom token into a strongly-typed `LogoOperator`.
    func parseOperator(_ token: String) -> LogoOperator?

    /// Parses a localized/custom token into a strongly-typed `LogoHeading`.
    func parseHeading(_ token: String) -> LogoHeading?

    /// Parses a localized/custom token into a boolean value.
    func parseBoolean(_ token: String) -> Bool?

    /// Parses a localized/custom token into a `BoxExitPosition`.
    func parseExitPosition(_ token: String) -> BoxExitPosition?

    /// Parses a localized/custom token into a `BorderStyle`.
    func parseBorderStyle(_ token: String) -> BorderStyle?

    /// Parses a localized/custom token into a `Calendar.Identifier`.
    func parseCalendarIdentifier(_ token: String) -> Calendar.Identifier?

    /// Parses a localized/custom token into a `LogoDateTimeStylePreset`.
    func parseDateTimeStylePreset(_ token: String) -> LogoDateTimeStylePreset?

    /// Parses a localized/custom token into a `LogoNumberStyle`.
    func parseNumberStyle(_ token: String) -> LogoNumberStyle?

    /// Parses a localized/custom token into a `LogoListType`.
    func parseListType(_ token: String) -> LogoListType?

    /// Parses a localized/custom token into a `LogoByteCountStyle`.
    func parseByteCountStyle(_ token: String) -> LogoByteCountStyle?

    /// Parses a localized/custom token into a `LogoPersonNameStyle`.
    func parsePersonNameStyle(_ token: String) -> LogoPersonNameStyle?

    /// Parses a localized/custom token into a `LogoPersonNameField`.
    func parsePersonNameField(_ token: String) -> LogoPersonNameField?

    /// Parses a localized/custom token into a `LogoFormatOptionField`.
    func parseFormatOptionField(_ token: String) -> LogoFormatOptionField?

    /// Set of grammatical filler / noise tokens (e.g. noise words) provided by this plugin.
    var fillerTokens: Set<String> { get }

    /// Returns whether the given token is a grammatical filler / noise token that should be skipped during argument parsing.
    func isFillerToken(_ token: String) -> Bool

    /// All keyword aliases provided by this plugin (for auto-completion and syntax highlighting).
    var keywordAliases: [String] { get }

    /// Returns all dialect aliases for the specified primitive.
    func aliases(for primitive: LogoPrimitive) -> [String]
}

public extension LogoParserPlugin {
    var displayName: String { id }
    var aliases: [String] { [] }
    func parsePrimitive(_ token: String) -> LogoPrimitive? { nil }
    func parseOperator(_ token: String) -> LogoOperator? { nil }
    func parseHeading(_ token: String) -> LogoHeading? { nil }
    func parseBoolean(_ token: String) -> Bool? { nil }
    func parseExitPosition(_ token: String) -> BoxExitPosition? { nil }
    func parseBorderStyle(_ token: String) -> BorderStyle? { nil }
    func parseCalendarIdentifier(_ token: String) -> Calendar.Identifier? { nil }
    func parseDateTimeStylePreset(_ token: String) -> LogoDateTimeStylePreset? { nil }
    func parseNumberStyle(_ token: String) -> LogoNumberStyle? { nil }
    func parseListType(_ token: String) -> LogoListType? { nil }
    func parseByteCountStyle(_ token: String) -> LogoByteCountStyle? { nil }
    func parsePersonNameStyle(_ token: String) -> LogoPersonNameStyle? { nil }
    func parsePersonNameField(_ token: String) -> LogoPersonNameField? { nil }
    func parseFormatOptionField(_ token: String) -> LogoFormatOptionField? { nil }
    var fillerTokens: Set<String> { [] }
    func isFillerToken(_ token: String) -> Bool {
        fillerTokens.contains(token.lowercased())
    }
    var keywordAliases: [String] { [] }
    func aliases(for primitive: LogoPrimitive) -> [String] { [] }
}
