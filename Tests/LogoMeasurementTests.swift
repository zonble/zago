import Foundation
import Testing

@testable import LogoEngine

struct LogoMeasurementTests {
    private func eval(_ expression: String, engine: LogoEngine = LogoEngine()) -> String {
        let tokens = LogoTokenizer.tokenize(expression)
        var index = 0
        return engine.evaluateExpression(tokens, index: &index)
    }

    @Test func testConvertArea() throws {
        #expect(eval("CONVERT.AREA 1 \"sqm \"sqft").starts(with: "10.7639"))
        #expect(eval("CONVERT.AREA 1 \"sqkm \"sqm") == "1000000")
        #expect(eval("CONVERT.AREA 1 \"ha \"sqm") == "10000")
    }

    @Test func testConvertLength() throws {
        #expect(eval("CONVERT.LENGTH 1000 \"m \"km") == "1")
        #expect(eval("CONVERT.LENGTH 1 \"in \"cm") == "2.54")
        #expect(eval("CONVERT.LENGTH 1 \"ft \"in") == "12")
        #expect(eval("CONVERT.LENGTH 1 \"yd \"ft") == "3")
        let miToFt = Double(eval("CONVERT.LENGTH 1 \"mi \"ft")) ?? 0
        #expect(abs(miToFt - 5280) < 0.1)
    }

    @Test func testConvertVolume() throws {
        #expect(eval("CONVERT.VOLUME 1000 \"ml \"l") == "1")
        #expect(eval("CONVERT.VOLUME 1 \"l \"ml") == "1000")
        #expect(eval("CONVERT.VOLUME 1 \"m3 \"l") == "1000")
        #expect(eval("CONVERT.VOLUME 1 \"gal \"qt") == "4")
    }

    @Test func testConvertAngle() throws {
        #expect(eval("CONVERT.ANGLE 180 \"deg \"rad") == "3.141592654")
        #expect(eval("CONVERT.ANGLE 1 \"rev \"deg") == "360")
        #expect(eval("CONVERT.ANGLE 360 \"deg \"rev") == "1")
    }

    @Test func testConvertMass() throws {
        #expect(eval("CONVERT.MASS 1 \"kg \"g") == "1000")
        #expect(eval("CONVERT.MASS 1 \"t \"kg") == "1000")
        #expect(eval("CONVERT.MASS 1 \"lb \"oz") == "16")
    }

    @Test func testConvertPressure() throws {
        #expect(eval("CONVERT.PRESSURE 1 \"bar \"kpa") == "100")
        #expect(eval("CONVERT.PRESSURE 1 \"hpa \"pa") == "100")
    }

    @Test func testConvertAcceleration() throws {
        #expect(eval("CONVERT.ACCELERATION 1 \"g \"m/s2") == "9.81")
    }

    @Test func testConvertDuration() throws {
        #expect(eval("CONVERT.DURATION 1 \"hr \"min") == "60")
        #expect(eval("CONVERT.DURATION 2 \"min \"s") == "120")
        #expect(eval("CONVERT.DURATION 1000 \"ms \"s") == "1")
    }

    @Test func testConvertFrequency() throws {
        #expect(eval("CONVERT.FREQUENCY 1 \"ghz \"mhz") == "1000")
        #expect(eval("CONVERT.FREQUENCY 1 \"mhz \"khz") == "1000")
        #expect(eval("CONVERT.FREQUENCY 1 \"khz \"hz") == "1000")
    }

    @Test func testConvertSpeed() throws {
        #expect(eval("CONVERT.SPEED 36 \"kmh \"m/s") == "10")
    }

    @Test func testConvertEnergy() throws {
        #expect(eval("CONVERT.ENERGY 1 \"kj \"j") == "1000")
        #expect(eval("CONVERT.ENERGY 1 \"kcal \"cal") == "1000")
        #expect(eval("CONVERT.ENERGY 1 \"kwh \"j") == "3600000")
    }

    @Test func testConvertPower() throws {
        #expect(eval("CONVERT.POWER 1 \"kw \"w") == "1000")
        #expect(eval("CONVERT.POWER 1 \"megawatt \"kw") == "1000")
    }

    @Test func testConvertTemperature() throws {
        #expect(eval("CONVERT.TEMPERATURE 0 \"c \"f") == "32")
        #expect(eval("CONVERT.TEMPERATURE 100 \"c \"f") == "212")
        #expect(eval("CONVERT.TEMPERATURE 0 \"c \"k") == "273.15")
    }

    @Test func testConvertIlluminance() throws {
        #expect(eval("CONVERT.ILLUMINANCE 100 \"lx \"lx") == "100")
    }

    @Test func testConvertElectricCharge() throws {
        #expect(eval("CONVERT.ELECTRICCHARGE 5000 \"mah \"ah") == "5")
        #expect(eval("CONVERT.ELECTRIC.CHARGE 1 \"ah \"mah") == "1000")
    }

    @Test func testConvertElectricCurrent() throws {
        #expect(eval("CONVERT.ELECTRICCURRENT 1500 \"ma \"a") == "1.5")
    }

    @Test func testConvertElectricPotentialDifference() throws {
        #expect(eval("CONVERT.ELECTRICPOTENTIALDIFFERENCE 5 \"v \"mv") == "5000")
        #expect(eval("CONVERT.VOLTAGE 1 \"kv \"v") == "1000")
    }

    @Test func testConvertElectricResistance() throws {
        #expect(eval("CONVERT.ELECTRICRESISTANCE 1 \"kohm \"ohm") == "1000")
    }

    @Test func testConvertConcentrationMass() throws {
        #expect(eval("CONVERT.CONCENTRATIONMASS 1 \"g/l \"mg/dl") == "100")
    }

    @Test func testConvertDispersion() throws {
        #expect(eval("CONVERT.DISPERSION 10 \"ppm \"ppm") == "10")
    }

    @Test func testConvertFuelEfficiency() throws {
        let res = eval("CONVERT.FUELEFFICIENCY 30 \"mpg \"l/100km")
        #expect(res.starts(with: "7.84"))
    }

    @Test func testConvertInformationStorage() throws {
        #expect(eval("CONVERT.INFORMATIONSTORAGE 1 \"gb \"mb") == "1000")
        #expect(eval("CONVERT.INFORMATIONSTORAGE 1 \"mb \"kb") == "1000")
        #expect(eval("CONVERT.INFORMATIONSTORAGE 1 \"gib \"mib") == "1024")
        #expect(eval("CONVERT.INFORMATIONSTORAGE 1 \"byte \"bit") == "8")
        #expect(eval("CONVERT.STORAGE 1024 \"kib \"mib") == "1")
    }

    @Test func testParenthesizedConvert() throws {
        #expect(eval("(CONVERT.LENGTH 100 \"m \"cm)") == "10000")
    }

    #if !os(Linux) && !os(Windows)
    @Test func testFormatLength() throws {
        let res1 = eval("FORMAT.LENGTH 100 \"m")
        #expect(!res1.isEmpty)
        let res2 = eval("FORMAT.LENGTH 1500 \"m \"long \"zh_TW \"true")
        #expect(res2.contains("公里") || res2.contains("1.5"))
    }

    @Test func testFormatTemperature() throws {
        let res = eval("FORMAT.TEMPERATURE 25 \"c \"short")
        #expect(res.contains("25") && (res.contains("°C") || res.contains("C") || res.contains("deg")))
    }

    @Test func testFormatStorage() throws {
        let res = eval("FORMAT.STORAGE 16 \"gb")
        #expect(res.contains("16") && (res.contains("GB") || res.contains("gb") || res.contains("gigabytes")))
    }

    @Test func testParenthesizedFormat() throws {
        let res = eval("(FORMAT.SPEED 100 \"kmh \"short)")
        #expect(!res.isEmpty)
    }

    @Test func testFormatAngleWithSmartLocaleDisambiguation() throws {
        let resDirectLocale = eval("FORMAT.ANGLE 10 \"deg \"zh_TW")
        #expect(resDirectLocale == "10°")

        let resLongLocale = eval("FORMAT.ANGLE 10 \"deg \"long \"zh_TW")
        #expect(resLongLocale == "10度")

        let resReversedOrder = eval("FORMAT.ANGLE 10 \"deg \"zh_TW \"long")
        #expect(resReversedOrder == "10度")

        let resListDirect = eval("FORMAT.ANGLE 10 \"deg [\"zh_TW \"long]")
        #expect(resListDirect == "10度")

        let resListNamed = eval("FORMAT.ANGLE 10 \"deg [locale \"zh_TW style \"long]")
        #expect(resListNamed == "10度")

        let resParenthesized = eval("(FORMAT.ANGLE 10 \"deg \"zh_TW \"long)")
        #expect(resParenthesized == "10度")
    }
    #else
    @Test func testFormatMeasurementReportsUnsupportedOnNonDarwin() throws {
        let engine = LogoEngine()
        _ = eval("FORMAT.LENGTH 100 \"m", engine: engine)
        #expect(engine.lastError?.message.contains("not supported on this platform") == true)
    }
    #endif
}
