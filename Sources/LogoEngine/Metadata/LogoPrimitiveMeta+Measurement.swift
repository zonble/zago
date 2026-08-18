import Foundation

extension LogoPrimitive {
    private static let supportedUnitsNote: String = """
        Supported measurement dimensions and units:
        • Area: sqm, m2, sqkm, km2, sqcm, cm2, sqmm, mm2, squm, sqnm, sqin, in2, sqft, ft2, sqyd, yd2, sqmi, mi2, acre, are, ha
        • Length: m, km, cm, mm, um, nm, pm, dm, dam, hm, in, ft, yd, mi, nmi, furlong, fathom, ly, pc, au
        • Volume: l, ml, cl, dl, kl, m3, km3, cm3, mm3, in3, ft3, yd3, mi3, acrefeet, bushel, tsp, tbsp, floz, cup, pt, qt, gal
        • Angle: deg, rad, grad, rev, arcmin, arcsec
        • Mass: kg, g, mg, ug, ng, pg, t, lb, oz, ozt, ct, st, slug
        • Pressure: pa, hpa, kpa, mpa, gpa, bar, mbar, atm, mmhg, torr, inhg, psi
        • Acceleration: m/s2, gforce, gee, gravity
        • Duration: s, sec, min, hr, h, day, d, ms, us, ns, ps
        • Frequency: hz, khz, mhz, ghz, thz, fps, rpm
        • Speed: m/s, km/h, kmh, mph, knot, kn
        • Energy: j, kj, mj, gj, cal, kcal, wh, kwh, mwh, btu, ev
        • Power: w, kw, mw, gw, hp, ps
        • Temperature: c, celsius, f, fahrenheit, k, kelvin
        • Illuminance: lx, lux
        • Electric Charge: c, coulomb, ah, mah, uah
        • Electric Current: a, amp, ma, ua, ka
        • Voltage: v, mv, kv, uv, megavolt
        • Resistance: ohm, kohm, mohm, microohm
        • Concentration Mass: g/l, mg/dl, mmol/l
        • Dispersion: ppm
        • Fuel Efficiency: l/100km, mpg, imperialmpg
        • Information Storage: b, byte, kb, mb, gb, tb, pb, bit, kbit, mbit, gbit, kib, mib, gib, tib
        """

    var measurementMeta: LogoPrimitiveMeta? {
        switch self {
        case .convertMeasure:
            return LogoPrimitiveMeta(
                name: "CONVERT.MEASURE",
                description:
                    "Converts a measurement or numeric value between compatible units (e.g., m to km, kg to g, c to f).",
                localizedDescriptionKey: "logo.doc.convertmeasure",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(
                        name: "valueOrMeasurement", required: true,
                        description: "A numeric value or a measurement object [value unit].", example: "1000"),
                    LogoPrimitiveParameter(
                        name: "fromUnitOrTargetUnit", required: true,
                        description: "Source unit (if value is numeric) or target unit (if first arg is measurement).",
                        example: "m"),
                    LogoPrimitiveParameter(
                        name: "toUnit", required: false,
                        description: "Target unit for conversion (when first arg is numeric).", example: "km"),
                ],
                examples: [
                    LogoPrimitiveExample(input: "CONVERT.MEASURE 1000 \"m \"km", output: "1"),
                    LogoPrimitiveExample(input: "CONVERT.MEASURE 100 \"c \"f", output: "212"),
                    LogoPrimitiveExample(input: "CONVERT.MEASURE (MEASURE.ADD 1 kg 500 g) \"g", output: "1500"),
                ],
                notes: Self.supportedUnitsNote
            )

        // MARK: - FORMAT.MEASURE Metadata

        case .formatMeasure:
            return LogoPrimitiveMeta(
                name: "FORMAT.MEASURE",
                description:
                    "Formats a measurement or numeric value/unit pair into a localized string with unit symbols or names.",
                localizedDescriptionKey: "logo.doc.formatmeasure",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(
                        name: "measurementOrValue", required: true,
                        description: "A measurement object [value unit] or numeric value.", example: "[1.5 kg]"),
                    LogoPrimitiveParameter(
                        name: "unitOrTargetUnit", required: false, description: "Unit or target conversion unit.",
                        example: "g"),
                    LogoPrimitiveParameter(
                        name: "style", required: false, description: "Unit display style (short, medium, long).",
                        example: "long", allowedValues: ["medium", "short", "long"]),
                    LogoPrimitiveParameter(
                        name: "locale", required: false, description: "Target locale.", example: "zh_TW"),
                    LogoPrimitiveParameter(
                        name: "naturalScale", required: false, description: "Auto-scale unit to natural magnitude.",
                        example: "true"),
                ],
                examples: [
                    LogoPrimitiveExample(
                        input: "FORMAT.MEASURE (MEASURE.ADD 1 kg 100 g) \"g \"zh_TW", output: "1,100 g"),
                    LogoPrimitiveExample(input: "FORMAT.MEASURE 1500 \"m \"long \"zh_TW \"true", output: "1.5 公里"),
                ],
                notes: "Not supported on Linux or Windows.\n\n" + Self.supportedUnitsNote
            )

        case .measureAdd:
            return LogoPrimitiveMeta(
                name: "MEASURE.ADD",
                description:
                    "Adds two measurements with automatic unit conversion and returns the sum in the target unit.",
                localizedDescriptionKey: "logo.doc.measureadd",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(
                        name: "val1", required: true, description: "First measurement numeric value.", example: "5"),
                    LogoPrimitiveParameter(
                        name: "unit1", required: true, description: "First measurement unit.", example: "km"),
                    LogoPrimitiveParameter(
                        name: "val2", required: true, description: "Second measurement numeric value.", example: "300"),
                    LogoPrimitiveParameter(
                        name: "unit2", required: true, description: "Second measurement unit.", example: "m"),
                    LogoPrimitiveParameter(
                        name: "targetUnit", required: false,
                        description: "Target unit for the result (defaults to unit1).", example: "m"),
                ],
                examples: [LogoPrimitiveExample(input: "MEASURE.ADD 5 \"km 300 \"m \"m", output: "5300")],
                notes: Self.supportedUnitsNote
            )

        case .measureSub:
            return LogoPrimitiveMeta(
                name: "MEASURE.SUB",
                description: "Subtracts the second measurement from the first with automatic unit conversion.",
                localizedDescriptionKey: "logo.doc.measuresub",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(
                        name: "val1", required: true, description: "First measurement numeric value.", example: "1"),
                    LogoPrimitiveParameter(
                        name: "unit1", required: true, description: "First measurement unit.", example: "hr"),
                    LogoPrimitiveParameter(
                        name: "val2", required: true, description: "Second measurement numeric value.", example: "15"),
                    LogoPrimitiveParameter(
                        name: "unit2", required: true, description: "Second measurement unit.", example: "min"),
                    LogoPrimitiveParameter(
                        name: "targetUnit", required: false,
                        description: "Target unit for the result (defaults to unit1).", example: "min"),
                ],
                examples: [LogoPrimitiveExample(input: "MEASURE.SUB 1 \"hr 15 \"min \"min", output: "45")],
                notes: Self.supportedUnitsNote
            )

        case .measureScale:
            return LogoPrimitiveMeta(
                name: "MEASURE.SCALE",
                description: "Multiplies a measurement by a numeric scaling factor.",
                localizedDescriptionKey: "logo.doc.measurescale",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(
                        name: "value", required: true, description: "Numeric measurement value.", example: "2.5"),
                    LogoPrimitiveParameter(
                        name: "unit", required: true, description: "Measurement unit.", example: "km"),
                    LogoPrimitiveParameter(
                        name: "factor", required: true, description: "Scaling multiplier factor.", example: "3"),
                ],
                examples: [LogoPrimitiveExample(input: "MEASURE.SCALE 2.5 \"km 3", output: "7.5")],
                notes: Self.supportedUnitsNote
            )

        case .measureEqual:
            return LogoPrimitiveMeta(
                name: "MEASURE.EQUAL?",
                description:
                    "Tests whether two measurements represent equal physical quantities under unit conversion.",
                localizedDescriptionKey: "logo.doc.measureequal",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(
                        name: "val1", required: true, description: "First measurement value.", example: "1000"),
                    LogoPrimitiveParameter(
                        name: "unit1", required: true, description: "First measurement unit.", example: "m"),
                    LogoPrimitiveParameter(
                        name: "val2", required: true, description: "Second measurement value.", example: "1"),
                    LogoPrimitiveParameter(
                        name: "unit2", required: true, description: "Second measurement unit.", example: "km"),
                    LogoPrimitiveParameter(
                        name: "tolerance", required: false, description: "Comparison delta tolerance in unit1.",
                        example: "0.001"),
                ],
                examples: [LogoPrimitiveExample(input: "MEASURE.EQUAL? 1000 \"m 1 \"km", output: "true")],
                notes: Self.supportedUnitsNote
            )

        case .measureLess:
            return LogoPrimitiveMeta(
                name: "MEASURE.LESS?",
                description:
                    "Tests whether the first measurement is strictly less than the second under unit conversion.",
                localizedDescriptionKey: "logo.doc.measureless",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(
                        name: "val1", required: true, description: "First measurement value.", example: "500"),
                    LogoPrimitiveParameter(
                        name: "unit1", required: true, description: "First measurement unit.", example: "m"),
                    LogoPrimitiveParameter(
                        name: "val2", required: true, description: "Second measurement value.", example: "1"),
                    LogoPrimitiveParameter(
                        name: "unit2", required: true, description: "Second measurement unit.", example: "km"),
                ],
                examples: [LogoPrimitiveExample(input: "MEASURE.LESS? 500 \"m 1 \"km", output: "true")],
                notes: Self.supportedUnitsNote
            )

        case .measureGreater:
            return LogoPrimitiveMeta(
                name: "MEASURE.GREATER?",
                description:
                    "Tests whether the first measurement is strictly greater than the second under unit conversion.",
                localizedDescriptionKey: "logo.doc.measuregreater",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(
                        name: "val1", required: true, description: "First measurement value.", example: "1.5"),
                    LogoPrimitiveParameter(
                        name: "unit1", required: true, description: "First measurement unit.", example: "km"),
                    LogoPrimitiveParameter(
                        name: "val2", required: true, description: "Second measurement value.", example: "1000"),
                    LogoPrimitiveParameter(
                        name: "unit2", required: true, description: "Second measurement unit.", example: "m"),
                ],
                examples: [LogoPrimitiveExample(input: "MEASURE.GREATER? 1.5 \"km 1000 \"m", output: "true")],
                notes: Self.supportedUnitsNote
            )

        case .measureMin:
            return LogoPrimitiveMeta(
                name: "MEASURE.MIN",
                description: "Returns the smaller of two measurements in the requested target unit.",
                localizedDescriptionKey: "logo.doc.measuremin",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(
                        name: "val1", required: true, description: "First measurement value.", example: "1"),
                    LogoPrimitiveParameter(
                        name: "unit1", required: true, description: "First measurement unit.", example: "km"),
                    LogoPrimitiveParameter(
                        name: "val2", required: true, description: "Second measurement value.", example: "800"),
                    LogoPrimitiveParameter(
                        name: "unit2", required: true, description: "Second measurement unit.", example: "m"),
                    LogoPrimitiveParameter(
                        name: "targetUnit", required: false,
                        description: "Target unit for the result (defaults to unit1).", example: "m"),
                ],
                examples: [LogoPrimitiveExample(input: "MEASURE.MIN 1 \"km 800 \"m \"m", output: "800")],
                notes: Self.supportedUnitsNote
            )

        case .measureMax:
            return LogoPrimitiveMeta(
                name: "MEASURE.MAX",
                description: "Returns the larger of two measurements in the requested target unit.",
                localizedDescriptionKey: "logo.doc.measuremax",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(
                        name: "val1", required: true, description: "First measurement value.", example: "1"),
                    LogoPrimitiveParameter(
                        name: "unit1", required: true, description: "First measurement unit.", example: "km"),
                    LogoPrimitiveParameter(
                        name: "val2", required: true, description: "Second measurement value.", example: "800"),
                    LogoPrimitiveParameter(
                        name: "unit2", required: true, description: "Second measurement unit.", example: "m"),
                    LogoPrimitiveParameter(
                        name: "targetUnit", required: false,
                        description: "Target unit for the result (defaults to unit1).", example: "m"),
                ],
                examples: [LogoPrimitiveExample(input: "MEASURE.MAX 1 \"km 800 \"m \"m", output: "1000")],
                notes: Self.supportedUnitsNote
            )

        default:
            return nil
        }
    }
}
