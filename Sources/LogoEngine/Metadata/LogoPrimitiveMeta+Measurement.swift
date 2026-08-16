import Foundation

extension LogoPrimitive {
    var measurementMeta: LogoPrimitiveMeta? {
        switch self {
        case .convertArea:
            return LogoPrimitiveMeta(
                name: "CONVERT.AREA",
                description: "Converts area measurements between units (e.g. sqm, sqft, acres, hectares).",
                localizedDescriptionKey: "logo.doc.convertarea",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "value", required: true, description: "The numeric area value.", example: "1"),
                    LogoPrimitiveParameter(name: "fromUnit", required: true, description: "Source area unit (sqm, sqft, sqkm, acres, hectares).", example: "sqm"),
                    LogoPrimitiveParameter(name: "toUnit", required: true, description: "Target area unit.", example: "sqft"),
                ],
                examples: [LogoPrimitiveExample(input: "CONVERT.AREA 1 \"sqm \"sqft", output: "10.763910416709722")]
            )

        case .convertLength:
            return LogoPrimitiveMeta(
                name: "CONVERT.LENGTH",
                description: "Converts length/distance measurements between units (e.g. m, km, cm, mm, in, ft, yd, mi, nmi).",
                localizedDescriptionKey: "logo.doc.convertlength",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "value", required: true, description: "The numeric length value.", example: "100"),
                    LogoPrimitiveParameter(name: "fromUnit", required: true, description: "Source length unit (m, km, cm, mm, in, ft, yd, mi).", example: "m"),
                    LogoPrimitiveParameter(name: "toUnit", required: true, description: "Target length unit.", example: "ft"),
                ],
                examples: [LogoPrimitiveExample(input: "CONVERT.LENGTH 100 \"m \"ft", output: "328.0839895013123")]
            )

        case .convertVolume:
            return LogoPrimitiveMeta(
                name: "CONVERT.VOLUME",
                description: "Converts volume measurements between units (e.g. l, ml, gal, cups, tbsp, tsp, m3, cuft).",
                localizedDescriptionKey: "logo.doc.convertvolume",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "value", required: true, description: "The numeric volume value.", example: "1"),
                    LogoPrimitiveParameter(name: "fromUnit", required: true, description: "Source volume unit.", example: "gal"),
                    LogoPrimitiveParameter(name: "toUnit", required: true, description: "Target volume unit.", example: "l"),
                ],
                examples: [LogoPrimitiveExample(input: "CONVERT.VOLUME 1 \"gal \"l", output: "3.785411784")]
            )

        case .convertAngle:
            return LogoPrimitiveMeta(
                name: "CONVERT.ANGLE",
                description: "Converts angle measurements between units (e.g. deg, rad, grad, rev, arcmin, arcsec).",
                localizedDescriptionKey: "logo.doc.convertangle",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "value", required: true, description: "The numeric angle value.", example: "180"),
                    LogoPrimitiveParameter(name: "fromUnit", required: true, description: "Source angle unit.", example: "deg"),
                    LogoPrimitiveParameter(name: "toUnit", required: true, description: "Target angle unit.", example: "rad"),
                ],
                examples: [LogoPrimitiveExample(input: "CONVERT.ANGLE 180 \"deg \"rad", output: "3.141592653589793")]
            )

        case .convertMass:
            return LogoPrimitiveMeta(
                name: "CONVERT.MASS",
                description: "Converts mass/weight measurements between units (e.g. kg, g, mg, lb, oz, ton, ct, stone).",
                localizedDescriptionKey: "logo.doc.convertmass",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "value", required: true, description: "The numeric mass value.", example: "1"),
                    LogoPrimitiveParameter(name: "fromUnit", required: true, description: "Source mass unit.", example: "kg"),
                    LogoPrimitiveParameter(name: "toUnit", required: true, description: "Target mass unit.", example: "lb"),
                ],
                examples: [LogoPrimitiveExample(input: "CONVERT.MASS 1 \"kg \"lb", output: "2.2046226218487757")]
            )

        case .convertPressure:
            return LogoPrimitiveMeta(
                name: "CONVERT.PRESSURE",
                description: "Converts pressure measurements between units (e.g. pa, hpa, kpa, bar, mbar, atm, psi, mmhg).",
                localizedDescriptionKey: "logo.doc.convertpressure",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "value", required: true, description: "The numeric pressure value.", example: "1"),
                    LogoPrimitiveParameter(name: "fromUnit", required: true, description: "Source pressure unit.", example: "atm"),
                    LogoPrimitiveParameter(name: "toUnit", required: true, description: "Target pressure unit.", example: "psi"),
                ],
                examples: [LogoPrimitiveExample(input: "CONVERT.PRESSURE 1 \"atm \"psi", output: "14.69594877551345")]
            )

        case .convertAcceleration:
            return LogoPrimitiveMeta(
                name: "CONVERT.ACCELERATION",
                description: "Converts acceleration measurements between units (m/s2, g).",
                localizedDescriptionKey: "logo.doc.convertacceleration",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "value", required: true, description: "The numeric acceleration value.", example: "1"),
                    LogoPrimitiveParameter(name: "fromUnit", required: true, description: "Source acceleration unit.", example: "g"),
                    LogoPrimitiveParameter(name: "toUnit", required: true, description: "Target acceleration unit.", example: "m/s2"),
                ],
                examples: [LogoPrimitiveExample(input: "CONVERT.ACCELERATION 1 \"g \"m/s2", output: "9.80665")]
            )

        case .convertDuration:
            return LogoPrimitiveMeta(
                name: "CONVERT.DURATION",
                description: "Converts time durations between units (s, min, hr, ms, us, ns, ps).",
                localizedDescriptionKey: "logo.doc.convertduration",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "value", required: true, description: "The numeric duration value.", example: "2"),
                    LogoPrimitiveParameter(name: "fromUnit", required: true, description: "Source duration unit.", example: "hr"),
                    LogoPrimitiveParameter(name: "toUnit", required: true, description: "Target duration unit.", example: "min"),
                ],
                examples: [LogoPrimitiveExample(input: "CONVERT.DURATION 2 \"hr \"min", output: "120")]
            )

        case .convertFrequency:
            return LogoPrimitiveMeta(
                name: "CONVERT.FREQUENCY",
                description: "Converts frequency measurements between units (hz, khz, mhz, ghz, thz, fps).",
                localizedDescriptionKey: "logo.doc.convertfrequency",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "value", required: true, description: "The numeric frequency value.", example: "1"),
                    LogoPrimitiveParameter(name: "fromUnit", required: true, description: "Source frequency unit.", example: "ghz"),
                    LogoPrimitiveParameter(name: "toUnit", required: true, description: "Target frequency unit.", example: "mhz"),
                ],
                examples: [LogoPrimitiveExample(input: "CONVERT.FREQUENCY 1 \"ghz \"mhz", output: "1000")]
            )

        case .convertSpeed:
            return LogoPrimitiveMeta(
                name: "CONVERT.SPEED",
                description: "Converts speed measurements between units (m/s, kmh, mph, knots).",
                localizedDescriptionKey: "logo.doc.convertspeed",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "value", required: true, description: "The numeric speed value.", example: "100"),
                    LogoPrimitiveParameter(name: "fromUnit", required: true, description: "Source speed unit.", example: "kmh"),
                    LogoPrimitiveParameter(name: "toUnit", required: true, description: "Target speed unit.", example: "mph"),
                ],
                examples: [LogoPrimitiveExample(input: "CONVERT.SPEED 100 \"kmh \"mph", output: "62.13711922373339")]
            )

        case .convertEnergy:
            return LogoPrimitiveMeta(
                name: "CONVERT.ENERGY",
                description: "Converts energy measurements between units (j, kj, cal, kcal, kwh).",
                localizedDescriptionKey: "logo.doc.convertenergy",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "value", required: true, description: "The numeric energy value.", example: "1"),
                    LogoPrimitiveParameter(name: "fromUnit", required: true, description: "Source energy unit.", example: "kwh"),
                    LogoPrimitiveParameter(name: "toUnit", required: true, description: "Target energy unit.", example: "j"),
                ],
                examples: [LogoPrimitiveExample(input: "CONVERT.ENERGY 1 \"kwh \"j", output: "3600000")]
            )

        case .convertPower:
            return LogoPrimitiveMeta(
                name: "CONVERT.POWER",
                description: "Converts power measurements between units (w, kw, mw, gw, hp).",
                localizedDescriptionKey: "logo.doc.convertpower",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "value", required: true, description: "The numeric power value.", example: "1"),
                    LogoPrimitiveParameter(name: "fromUnit", required: true, description: "Source power unit.", example: "hp"),
                    LogoPrimitiveParameter(name: "toUnit", required: true, description: "Target power unit.", example: "w"),
                ],
                examples: [LogoPrimitiveExample(input: "CONVERT.POWER 1 \"hp \"w", output: "745.6998715822702")]
            )

        case .convertTemperature:
            return LogoPrimitiveMeta(
                name: "CONVERT.TEMPERATURE",
                description: "Converts temperature measurements between units (c, f, k).",
                localizedDescriptionKey: "logo.doc.converttemperature",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "value", required: true, description: "The numeric temperature value.", example: "100"),
                    LogoPrimitiveParameter(name: "fromUnit", required: true, description: "Source temperature unit (c, f, k).", example: "c"),
                    LogoPrimitiveParameter(name: "toUnit", required: true, description: "Target temperature unit (c, f, k).", example: "f"),
                ],
                examples: [LogoPrimitiveExample(input: "CONVERT.TEMPERATURE 100 \"c \"f", output: "212")]
            )

        case .convertIlluminance:
            return LogoPrimitiveMeta(
                name: "CONVERT.ILLUMINANCE",
                description: "Converts illuminance measurements (lx).",
                localizedDescriptionKey: "logo.doc.convertilluminance",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "value", required: true, description: "The numeric illuminance value.", example: "100"),
                    LogoPrimitiveParameter(name: "fromUnit", required: true, description: "Source illuminance unit.", example: "lx"),
                    LogoPrimitiveParameter(name: "toUnit", required: true, description: "Target illuminance unit.", example: "lx"),
                ],
                examples: [LogoPrimitiveExample(input: "CONVERT.ILLUMINANCE 100 \"lx \"lx", output: "100")]
            )

        case .convertElectricCharge:
            return LogoPrimitiveMeta(
                name: "CONVERT.ELECTRICCHARGE",
                description: "Converts electric charge measurements between units (c, ah, mah, uah).",
                localizedDescriptionKey: "logo.doc.convertelectriccharge",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "value", required: true, description: "The numeric electric charge value.", example: "5000"),
                    LogoPrimitiveParameter(name: "fromUnit", required: true, description: "Source charge unit.", example: "mah"),
                    LogoPrimitiveParameter(name: "toUnit", required: true, description: "Target charge unit.", example: "ah"),
                ],
                examples: [LogoPrimitiveExample(input: "CONVERT.ELECTRICCHARGE 5000 \"mah \"ah", output: "5")]
            )

        case .convertElectricCurrent:
            return LogoPrimitiveMeta(
                name: "CONVERT.ELECTRICCURRENT",
                description: "Converts electric current measurements between units (a, ma, ua, ka).",
                localizedDescriptionKey: "logo.doc.convertelectriccurrent",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "value", required: true, description: "The numeric electric current value.", example: "1.5"),
                    LogoPrimitiveParameter(name: "fromUnit", required: true, description: "Source current unit.", example: "a"),
                    LogoPrimitiveParameter(name: "toUnit", required: true, description: "Target current unit.", example: "ma"),
                ],
                examples: [LogoPrimitiveExample(input: "CONVERT.ELECTRICCURRENT 1.5 \"a \"ma", output: "1500")]
            )

        case .convertElectricPotentialDifference:
            return LogoPrimitiveMeta(
                name: "CONVERT.ELECTRICPOTENTIALDIFFERENCE",
                description: "Converts voltage / electric potential difference measurements between units (v, mv, uv, kv, megavolt).",
                localizedDescriptionKey: "logo.doc.convertelectricpotentialdifference",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "value", required: true, description: "The numeric voltage value.", example: "5"),
                    LogoPrimitiveParameter(name: "fromUnit", required: true, description: "Source voltage unit.", example: "v"),
                    LogoPrimitiveParameter(name: "toUnit", required: true, description: "Target voltage unit.", example: "mv"),
                ],
                examples: [LogoPrimitiveExample(input: "CONVERT.ELECTRICPOTENTIALDIFFERENCE 5 \"v \"mv", output: "5000")]
            )

        case .convertElectricResistance:
            return LogoPrimitiveMeta(
                name: "CONVERT.ELECTRICRESISTANCE",
                description: "Converts electric resistance measurements between units (ohm, kohm, megaohm, mohm).",
                localizedDescriptionKey: "logo.doc.convertelectricresistance",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "value", required: true, description: "The numeric resistance value.", example: "1"),
                    LogoPrimitiveParameter(name: "fromUnit", required: true, description: "Source resistance unit.", example: "kohm"),
                    LogoPrimitiveParameter(name: "toUnit", required: true, description: "Target resistance unit.", example: "ohm"),
                ],
                examples: [LogoPrimitiveExample(input: "CONVERT.ELECTRICRESISTANCE 1 \"kohm \"ohm", output: "1000")]
            )

        case .convertConcentrationMass:
            return LogoPrimitiveMeta(
                name: "CONVERT.CONCENTRATIONMASS",
                description: "Converts concentration mass measurements between units (g/l, mg/dl, mmol/l).",
                localizedDescriptionKey: "logo.doc.convertconcentrationmass",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "value", required: true, description: "The numeric concentration value.", example: "1"),
                    LogoPrimitiveParameter(name: "fromUnit", required: true, description: "Source concentration unit.", example: "g/l"),
                    LogoPrimitiveParameter(name: "toUnit", required: true, description: "Target concentration unit.", example: "mg/dl"),
                ],
                examples: [LogoPrimitiveExample(input: "CONVERT.CONCENTRATIONMASS 1 \"g/l \"mg/dl", output: "100")]
            )

        case .convertDispersion:
            return LogoPrimitiveMeta(
                name: "CONVERT.DISPERSION",
                description: "Converts dispersion measurements (ppm).",
                localizedDescriptionKey: "logo.doc.convertdispersion",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "value", required: true, description: "The numeric dispersion value.", example: "10"),
                    LogoPrimitiveParameter(name: "fromUnit", required: true, description: "Source dispersion unit.", example: "ppm"),
                    LogoPrimitiveParameter(name: "toUnit", required: true, description: "Target dispersion unit.", example: "ppm"),
                ],
                examples: [LogoPrimitiveExample(input: "CONVERT.DISPERSION 10 \"ppm \"ppm", output: "10")]
            )

        case .convertFuelEfficiency:
            return LogoPrimitiveMeta(
                name: "CONVERT.FUELEFFICIENCY",
                description: "Converts fuel efficiency measurements between units (l/100km, mpg, imperial mpg).",
                localizedDescriptionKey: "logo.doc.convertfuelefficiency",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "value", required: true, description: "The numeric fuel efficiency value.", example: "30"),
                    LogoPrimitiveParameter(name: "fromUnit", required: true, description: "Source fuel efficiency unit.", example: "mpg"),
                    LogoPrimitiveParameter(name: "toUnit", required: true, description: "Target fuel efficiency unit.", example: "l/100km"),
                ],
                examples: [LogoPrimitiveExample(input: "CONVERT.FUELEFFICIENCY 30 \"mpg \"l/100km", output: "7.840487")]
            )

        case .convertInformationStorage:
            return LogoPrimitiveMeta(
                name: "CONVERT.INFORMATIONSTORAGE",
                description: "Converts data storage and memory measurements between units (b, kb, mb, gb, tb, pb, bit, kbit, mbit, gbit, kib, mib, gib, tib).",
                localizedDescriptionKey: "logo.doc.convertinformationstorage",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "value", required: true, description: "The numeric data storage value.", example: "1"),
                    LogoPrimitiveParameter(name: "fromUnit", required: true, description: "Source data storage unit (b, kb, mb, gb, tb, kib, mib, gib).", example: "gb"),
                    LogoPrimitiveParameter(name: "toUnit", required: true, description: "Target data storage unit.", example: "mb"),
                ],
                examples: [LogoPrimitiveExample(input: "CONVERT.INFORMATIONSTORAGE 1 \"gb \"mb", output: "1000")]
            )

        default:
            return nil
        }
    }
}
