import Testing

@testable import LogoEngine

@Suite struct LogoDetectorsTests {
    #if os(Linux) || os(Windows)
        @Test func detectorPrimitivesReportUnsupportedPlatform() {
            for name in ["DETECT.URL", "DETECT.EMAIL", "DETECT.PHONE", "DETECT.DATE", "DETECT.ADDRESS"] {
                let engine = LogoEngine()
                var index = 0
                _ = engine.evaluateExpression([name, "Visit https://example.com"], index: &index)
                #expect(engine.lastError?.message == "[LOGO Error: \(name) is not supported on this platform]")
            }
        }
    #else
        @Test func detectsURLsAndEmailsAsLogoLists() {
            let engine = LogoEngine()
            var index = 0
            let urls = engine.evaluateExpression(
                ["DETECT.URL", "Visit https://example.com and https://swift.org"], index: &index)
            #expect(urls == "[https://example.com https://swift.org]")

            index = 0
            let emails = engine.evaluateExpression(["(", "DETECT.EMAIL", "Mail team@example.com", ")"], index: &index)
            #expect(emails == "[team@example.com]")
        }

        @Test func detectsPhonesDatesAndAddresses() {
            let engine = LogoEngine()

            var index = 0
            let phone = engine.evaluateExpression(["DETECT.PHONE", "Call (415) 555-2671"], index: &index)
            #expect(phone.contains("415") && phone.contains("555"))

            index = 0
            let date = engine.evaluateExpression(["DETECT.DATE", "Meeting on January 5, 2027"], index: &index)
            #expect(date.contains("January") && date.contains("2027"))

            index = 0
            let address = engine.evaluateExpression(
                ["DETECT.ADDRESS", "Ship to 1600 Pennsylvania Avenue NW, Washington, DC"], index: &index)
            #expect(address.contains("Pennsylvania") || address.contains("Washington"))
        }
    #endif
}
