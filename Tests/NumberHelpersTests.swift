import Foundation
import Testing

@testable import NumberHelpers

@Suite struct NumberHelpersTests {

    @Test func testChineseNumbersUppercaseAndLowercase() {
        let upper = ChineseNumbers.generate(intPart: "12345", decPart: "67", digitCase: .uppercase)
        #expect(upper == "壹萬貳仟參佰肆拾伍點陸柒")

        let lower = ChineseNumbers.generate(intPart: "12345", decPart: "", digitCase: .lowercase)
        #expect(lower == "一萬二千三百四十五")

        let zero = ChineseNumbers.generate(intPart: "0", decPart: "", digitCase: .uppercase)
        #expect(zero == "零")
    }

    @Test func testRomanNumbersConversion() throws {
        #expect(try RomanNumbers.convert(input: 2026, style: .alphabets) == "MMXXVI")
        #expect(try RomanNumbers.convert(input: 4, style: .alphabets) == "IV")
        #expect(try RomanNumbers.convert(input: 9, style: .alphabets) == "IX")
        #expect(try RomanNumbers.convert(input: 12, style: .fullWidthUpper) == "Ⅻ")
        #expect(try RomanNumbers.convert(input: 11, style: .fullWidthLower) == "ⅺ")
    }

    @Test func testSuzhouNumbersGeneration() {
        let suzhou = SuzhouNumbers.generate(intPart: "123", decPart: "")
        #expect(!suzhou.isEmpty)
    }

    @Test func testNumberFormatHelperAllMethods() {
        #expect(NumberFormatHelper.formatWithGrouping(1234567.89, precision: 2) == "1,234,567.89")
        #expect(NumberFormatHelper.formatPercent(0.75, precision: 0) == "75%")
        #expect(NumberFormatHelper.formatCurrency(1234.5, currencyCode: "USD", precision: 2).contains("1,234.50"))
        #expect(NumberFormatHelper.formatOrdinal(1) == "1st")
        #expect(NumberFormatHelper.formatOrdinal(2) == "2nd")
        #expect(NumberFormatHelper.formatOrdinal(3) == "3rd")
        #expect(NumberFormatHelper.formatOrdinal(4) == "4th")
        #expect(NumberFormatHelper.formatOrdinal(11) == "11th")
        #expect(NumberFormatHelper.formatOrdinal(21) == "21st")
        #expect(NumberFormatHelper.formatBytes(1048576, isBinary: true) == "1 MB")
        #expect(NumberFormatHelper.formatBytes(1000000, isBinary: false) == "1 MB")
        #expect(NumberFormatHelper.formatFinancialChinese(12345) == "壹萬貳仟參佰肆拾伍")
        #expect(NumberFormatHelper.formatFinancialChinese(-100) == "負壹佰")
    }
}
