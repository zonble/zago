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

    @Test func testMeasurementArithmetic() throws {
        #expect(eval("MEASURE.ADD 5 \"km 300 \"m") == "[5.3 km]")
        #expect(eval("MEASURE.ADD 5 \"km 300 \"m \"m") == "[5300 m]")
        #expect(eval("MEASURE.SUB 1 \"hr 15 \"min \"min") == "[45 min]")
        #expect(eval("MEASURE.SCALE 2.5 \"km 3") == "[7.5 km]")
        #expect(eval("(MEASURE.ADD 1 \"m 50 \"cm \"cm)") == "[150 cm]")
        #expect(eval("MEASURE.ADD 1 \"gib 512 \"mib \"mib") == "[1536 mib]")
    }

    @Test func testMeasurementComparison() throws {
        #expect(eval("MEASURE.EQUAL? 1000 \"m 1 \"km") == "true")
        #expect(eval("MEASURE.EQUAL? 1000 \"m 2 \"km") == "false")
        #expect(eval("MEASURE.LESS? 500 \"m 1 \"km") == "true")
        #expect(eval("MEASURE.LESS? 1 \"km 500 \"m") == "false")
        #expect(eval("MEASURE.GREATER? 1.5 \"km 1000 \"m") == "true")
        #expect(eval("MEASURE.GREATER? 500 \"m 1 \"km") == "false")
        #expect(eval("MEASURE.MIN 1 \"km 800 \"m \"m") == "[800 m]")
        #expect(eval("MEASURE.MAX 1 \"km 800 \"m \"m") == "[1000 m]")
        #expect(eval("(MEASURE.LESS? 50 \"cm 1 \"m)") == "true")
        #expect(eval("(MEASURE.MAX 2 \"hr 90 \"min \"min)") == "[120 min]")
    }

    @Test func testMeasurementPipeliningAndDimensionSafety() throws {
        #if !os(Linux) && !os(Windows)
        // 1. Direct Pipeline into FORMAT.MEASURE with target unit conversion
        let resWithTarget = eval("FORMAT.MEASURE (MEASURE.ADD 1 \"kg 3 \"g) \"g \"zh_TW")
        #expect(resWithTarget.contains("1,003") || resWithTarget.contains("1003"))
        #expect(resWithTarget.contains("g") || resWithTarget.contains("克") || resWithTarget.contains("公克"))

        // 2. Direct Pipeline into FORMAT.MEASURE preserving default unit (kg)
        let resDefault = eval("FORMAT.MEASURE (MEASURE.ADD 1 \"kg 3 \"g) \"zh_TW")
        #expect(resDefault.contains("1.003"))
        #expect(resDefault.contains("公斤") || resDefault.contains("kg"))

        // 3. Unquoted unit words in nested call
        let resUnquoted = eval("FORMAT.MEASURE (MEASURE.ADD 1 kg 3 g) \"g \"zh_TW")
        #expect(resUnquoted.contains("1,003") || resUnquoted.contains("1003"))
        #expect(resUnquoted.contains("g") || resUnquoted.contains("克") || resUnquoted.contains("公克"))

        // 4. Passing incompatible unit 'km' as target conversion to mass measurement reports error
        let invalidUnitEngine = LogoEngine()
        let invalidUnitRes = eval("FORMAT.MEASURE (MEASURE.ADD 1 kg 100 g) km", engine: invalidUnitEngine)
        #expect(invalidUnitRes.isEmpty)
        #expect(invalidUnitEngine.lastError?.message.contains("invalid unit 'km'") == true)

        // 5. Direct nested unparenthesized format with English locale
        let resEn = eval("FORMAT.MEASURE MEASURE.ADD 1 kg 100 g en")
        #expect(!resEn.isEmpty)
        #expect(resEn.contains("1.1") || resEn.contains("2.425"))
        #endif
    }

    @Test func testMeasurementIncompatibleUnitsErrorReporting() throws {
        let engine1 = LogoEngine()
        let res = eval("MEASURE.ADD 5 \"km 300 \"kg", engine: engine1)
        #expect(res.isEmpty)
        #expect(engine1.lastError?.message.contains("Incompatible or invalid measurement units") == true)

        let engine2 = LogoEngine()
        let cmpRes = eval("MEASURE.EQUAL? 5 \"km 300 \"kg", engine: engine2)
        #expect(cmpRes == "false")
        #expect(engine2.lastError?.message.contains("Incompatible or invalid measurement units") == true)
    }

    #if !os(Linux) && !os(Windows)
    @Test func testFormatMeasureScalarValues() throws {
        let res1 = eval("FORMAT.MEASURE 100 \"m")
        #expect(!res1.isEmpty)
        let res2 = eval("FORMAT.MEASURE 1500 \"m \"long \"zh_TW \"true")
        #expect(res2.contains("公里") || res2.contains("1.5"))

        let resTemp = eval("FORMAT.MEASURE 25 \"c \"short")
        #expect(resTemp.contains("25") && (resTemp.contains("°C") || resTemp.contains("C") || resTemp.contains("deg")))

        let resStorage = eval("FORMAT.MEASURE 16 \"gb")
        #expect(resStorage.contains("16") && (resStorage.contains("GB") || resStorage.contains("gb") || resStorage.contains("gigabytes")))

        let resParen = eval("(FORMAT.MEASURE 100 \"kmh \"short)")
        #expect(!resParen.isEmpty)
    }

    @Test func testFormatMeasureWithSmartLocaleDisambiguation() throws {
        let resDirectLocale = eval("FORMAT.MEASURE 10 \"deg \"zh_TW")
        #expect(resDirectLocale == "10°")

        let resLongLocale = eval("FORMAT.MEASURE 10 \"deg \"long \"zh_TW")
        #expect(resLongLocale == "10度")

        let resReversedOrder = eval("FORMAT.MEASURE 10 \"deg \"zh_TW \"long")
        #expect(resReversedOrder == "10度")

        let resListDirect = eval("FORMAT.MEASURE 10 \"deg [\"zh_TW \"long]")
        #expect(resListDirect == "10度")

        let resListNamed = eval("FORMAT.MEASURE 10 \"deg [locale \"zh_TW style \"long]")
        #expect(resListNamed == "10度")

        let resParenthesized = eval("(FORMAT.MEASURE 10 \"deg \"zh_TW \"long)")
        #expect(resParenthesized == "10度")
    }

    @Test func testAll22MeasurementDimensionsFormatViaUnifiedFormatMeasure() throws {
        let commands = [
            ("FORMAT.MEASURE 100 \"sqm \"zh_TW", "平方公尺"),
            ("FORMAT.MEASURE 100 \"m \"zh_TW \"long", "公尺"),
            ("FORMAT.MEASURE 2 \"l \"zh_TW \"long", "公升"),
            ("FORMAT.MEASURE 90 \"deg \"zh_TW \"long", "度"),
            ("FORMAT.MEASURE 500 \"g \"zh_TW \"long", "克"),
            ("FORMAT.MEASURE 1 \"atm \"zh_TW", "atm"),
            ("FORMAT.MEASURE 9.81 \"m/s2 \"zh_TW", "公尺/平方秒"),
            ("FORMAT.MEASURE 2 \"hr \"zh_TW \"long", "小時"),
            ("FORMAT.MEASURE 60 \"hz \"zh_TW", "赫茲"),
            ("FORMAT.MEASURE 100 \"kmh \"zh_TW \"long", "公里"),
            ("FORMAT.MEASURE 2000 \"kcal \"zh_TW \"long", "卡路里"),
            ("FORMAT.MEASURE 100 \"kw \"zh_TW", "千瓦"),
            ("FORMAT.MEASURE 25 \"c \"zh_TW \"long", "度"),
            ("FORMAT.MEASURE 500 \"lx \"zh_TW", "勒克斯"),
            ("FORMAT.MEASURE 5000 \"mah \"zh_TW", "mAh"),
            ("FORMAT.MEASURE 2 \"amp \"zh_TW \"long", "安培"),
            ("FORMAT.MEASURE 110 \"v \"zh_TW \"long", "伏特"),
            ("FORMAT.MEASURE 10 \"kohm \"zh_TW", "10"),
            ("FORMAT.MEASURE 100 \"mg/dl \"zh_TW", "g/L"),
            ("FORMAT.MEASURE 10 \"ppm \"zh_TW", "百萬分率"),
            ("FORMAT.MEASURE 30 \"mpg \"zh_TW", "加侖"),
            ("FORMAT.MEASURE 16 \"gb \"zh_TW \"long", "GB"),
        ]

        for (cmd, expectedSubstring) in commands {
            let res = eval(cmd)
            #expect(!res.isEmpty, "Command returned empty: \(cmd)")
            #expect(res.contains(expectedSubstring), "Command \(cmd) returned \(res), expected substring \(expectedSubstring)")
        }
    }
    #else
    @Test func testFormatMeasurementReportsUnsupportedOnNonDarwin() throws {
        let engine = LogoEngine()
        _ = eval("FORMAT.MEASURE 100 \"m", engine: engine)
        #expect(engine.lastError?.message.contains("not supported on this platform") == true)
    }
    #endif
}
