import Foundation

/// Facade grouping Foundation-powered Number, List, RelativeDateTime, ByteCount, and PersonName formatters for LogoEngine.
public enum LogoFormatters {
    public typealias NumberStyle = LogoNumberStyle
    public typealias ListType = LogoListType
    public typealias ByteCountStyle = LogoByteCountStyle
    public typealias PersonNameStyle = LogoPersonNameStyle

    // MARK: - Number Formatter Facade

    public static func isCurrencyCode(_ raw: String) -> Bool {
        LogoNumberFormatter.isCurrencyCode(raw)
    }

    public static func disambiguateNumberOptions(
        _ args: [String],
        style: inout NumberStyle,
        locale: inout String?,
        currencyCode: inout String?,
        precision: inout Int?,
        parseStyle: ((String) -> NumberStyle?)? = nil
    ) {
        LogoNumberFormatter.disambiguateOptions(
            args,
            style: &style,
            locale: &locale,
            currencyCode: &currencyCode,
            precision: &precision,
            parseStyle: parseStyle
        )
    }

    public static func formatNumber(
        _ number: Double,
        style: NumberStyle = .decimal,
        locale: String? = nil,
        currencyCode: String? = nil,
        precision: Int? = nil
    ) -> String {
        LogoNumberFormatter.format(
            number,
            style: style,
            locale: locale,
            currencyCode: currencyCode,
            precision: precision
        )
    }

    public static func formatRoman(_ num: Int) -> String {
        LogoNumberFormatter.formatRoman(num)
    }

    public static func formatFinancialChinese(_ num: Int) -> String {
        LogoNumberFormatter.formatFinancialChinese(num)
    }

    // MARK: - List Formatter Facade

    public static func disambiguateListOptions(
        _ args: [String],
        type: inout ListType,
        locale: inout String?,
        parseType: ((String) -> ListType?)? = nil
    ) {
        LogoListFormatter.disambiguateOptions(args, type: &type, locale: &locale, parseType: parseType)
    }

    public static func formatList(
        _ items: [String],
        type: ListType = .and,
        locale: String? = nil
    ) -> String {
        LogoListFormatter.format(items, type: type, locale: locale)
    }

    // MARK: - Relative Date Time Formatter Facade

    public static func isRelativeTimeUnit(_ raw: String) -> Bool {
        LogoRelativeDateTimeFormatter.isRelativeTimeUnit(raw)
    }

    public static func disambiguateRelativeTimeOptions(
        _ args: [String],
        unit: inout String,
        locale: inout String?
    ) {
        LogoRelativeDateTimeFormatter.disambiguateOptions(args, unit: &unit, locale: &locale)
    }

    public static func formatRelativeTime(
        value: Double,
        unit: String,
        locale: String? = nil
    ) -> String {
        LogoRelativeDateTimeFormatter.formatTime(value: value, unit: unit, locale: locale)
    }

    public static func formatRelativeDate(
        target: Date,
        reference: Date = Date(),
        locale: String? = nil
    ) -> String {
        LogoRelativeDateTimeFormatter.formatDate(target: target, reference: reference, locale: locale)
    }

    // MARK: - Byte Count Formatter Facade

    public static func disambiguateBytesOptions(
        _ args: [String],
        style: inout ByteCountStyle,
        locale: inout String?,
        parseStyle: ((String) -> ByteCountStyle?)? = nil
    ) {
        LogoByteCountFormatter.disambiguateOptions(args, style: &style, locale: &locale, parseStyle: parseStyle)
    }

    public static func formatBytes(
        _ bytes: Int64,
        style: ByteCountStyle = .file,
        locale: String? = nil
    ) -> String {
        LogoByteCountFormatter.format(bytes, style: style, locale: locale)
    }

    // MARK: - Person Name Formatter Facade

    public static func disambiguatePersonNameOptions(
        _ args: [String],
        style: inout PersonNameStyle,
        locale: inout String?,
        parseStyle: ((String) -> PersonNameStyle?)? = nil
    ) {
        LogoPersonNameFormatter.disambiguateOptions(args, style: &style, locale: &locale, parseStyle: parseStyle)
    }

    public static func formatPersonName(
        givenName: String? = nil,
        familyName: String? = nil,
        middleName: String? = nil,
        prefix: String? = nil,
        suffix: String? = nil,
        nickname: String? = nil,
        fullName: String? = nil,
        style: PersonNameStyle = .default,
        locale: String? = nil
    ) -> String {
        LogoPersonNameFormatter.format(
            givenName: givenName,
            familyName: familyName,
            middleName: middleName,
            prefix: prefix,
            suffix: suffix,
            nickname: nickname,
            fullName: fullName,
            style: style,
            locale: locale
        )
    }
}
