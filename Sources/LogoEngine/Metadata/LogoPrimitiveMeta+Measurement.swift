import Foundation

extension LogoPrimitive {
    var measurementMeta: LogoPrimitiveMeta? {
        switch self {
        case .convertArea:
            let areaUnits = ["sqm", "m2", "sqkm", "km2", "sqcm", "cm2", "sqmm", "mm2", "squm", "sqnm", "sqin", "in2", "sqft", "ft2", "sqyd", "yd2", "sqmi", "mi2", "acre", "acres", "are", "ares", "ha", "hectares"]
            return LogoPrimitiveMeta(
                name: "CONVERT.AREA",
                description: "Converts area measurements between units (e.g. sqm, sqft, acres, hectares).",
                localizedDescriptionKey: "logo.doc.convertarea",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "value", required: true, description: "The numeric area value.", example: "1"),
                    LogoPrimitiveParameter(name: "fromUnit", required: true, description: "Source area unit (sqm, sqft, sqkm, acres, hectares).", example: "sqm", allowedValues: areaUnits),
                    LogoPrimitiveParameter(name: "toUnit", required: true, description: "Target area unit.", example: "sqft", allowedValues: areaUnits),
                ],
                examples: [LogoPrimitiveExample(input: "CONVERT.AREA 1 \"sqm \"sqft", output: "10.763910417")]
            )

        case .convertLength:
            let lengthUnits = ["m", "km", "cm", "mm", "um", "nm", "pm", "dm", "dam", "hm", "in", "ft", "yd", "mi", "nmi", "furlong", "fathom", "ly", "pc", "au"]
            return LogoPrimitiveMeta(
                name: "CONVERT.LENGTH",
                description: "Converts length/distance measurements between units (e.g. m, km, cm, mm, in, ft, yd, mi, nmi).",
                localizedDescriptionKey: "logo.doc.convertlength",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "value", required: true, description: "The numeric length value.", example: "100"),
                    LogoPrimitiveParameter(name: "fromUnit", required: true, description: "Source length unit (m, km, cm, mm, in, ft, yd, mi).", example: "m", allowedValues: lengthUnits),
                    LogoPrimitiveParameter(name: "toUnit", required: true, description: "Target length unit.", example: "ft", allowedValues: lengthUnits),
                ],
                examples: [LogoPrimitiveExample(input: "CONVERT.LENGTH 100 \"m \"ft", output: "328.083989501")]
            )

        case .convertVolume:
            let volumeUnits = ["l", "ml", "cl", "dl", "kl", "m3", "km3", "cm3", "mm3", "in3", "ft3", "yd3", "mi3", "acrefeet", "bushel", "tsp", "tbsp", "floz", "cup", "pt", "qt", "gal", "imptsp", "imptbsp", "impfloz", "imppt", "impqt", "impgal"]
            return LogoPrimitiveMeta(
                name: "CONVERT.VOLUME",
                description: "Converts volume measurements between units (e.g. l, ml, gal, cups, tbsp, tsp, m3, cuft).",
                localizedDescriptionKey: "logo.doc.convertvolume",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "value", required: true, description: "The numeric volume value.", example: "1"),
                    LogoPrimitiveParameter(name: "fromUnit", required: true, description: "Source volume unit.", example: "gal", allowedValues: volumeUnits),
                    LogoPrimitiveParameter(name: "toUnit", required: true, description: "Target volume unit.", example: "l", allowedValues: volumeUnits),
                ],
                examples: [LogoPrimitiveExample(input: "CONVERT.VOLUME 1 \"gal \"l", output: "3.785411784")]
            )

        case .convertAngle:
            let angleUnits = ["deg", "rad", "grad", "rev", "arcmin", "arcsec"]
            return LogoPrimitiveMeta(
                name: "CONVERT.ANGLE",
                description: "Converts angle measurements between units (e.g. deg, rad, grad, rev, arcmin, arcsec).",
                localizedDescriptionKey: "logo.doc.convertangle",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "value", required: true, description: "The numeric angle value.", example: "180"),
                    LogoPrimitiveParameter(name: "fromUnit", required: true, description: "Source angle unit.", example: "deg", allowedValues: angleUnits),
                    LogoPrimitiveParameter(name: "toUnit", required: true, description: "Target angle unit.", example: "rad", allowedValues: angleUnits),
                ],
                examples: [LogoPrimitiveExample(input: "CONVERT.ANGLE 180 \"deg \"rad", output: "3.141592654")]
            )

        case .convertMass:
            let massUnits = ["kg", "g", "mg", "ug", "ng", "pg", "t", "lb", "oz", "ozt", "ct", "st", "ston", "slug"]
            return LogoPrimitiveMeta(
                name: "CONVERT.MASS",
                description: "Converts mass/weight measurements between units (e.g. kg, g, mg, lb, oz, ton, ct, stone).",
                localizedDescriptionKey: "logo.doc.convertmass",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "value", required: true, description: "The numeric mass value.", example: "1"),
                    LogoPrimitiveParameter(name: "fromUnit", required: true, description: "Source mass unit.", example: "kg", allowedValues: massUnits),
                    LogoPrimitiveParameter(name: "toUnit", required: true, description: "Target mass unit.", example: "lb", allowedValues: massUnits),
                ],
                examples: [LogoPrimitiveExample(input: "CONVERT.MASS 1 \"kg \"lb", output: "2.204622622")]
            )

        case .convertPressure:
            let pressureUnits = ["pa", "hpa", "kpa", "mpa", "gpa", "bar", "mbar", "atm", "mmhg", "torr", "inhg", "psi"]
            return LogoPrimitiveMeta(
                name: "CONVERT.PRESSURE",
                description: "Converts pressure measurements between units (e.g. pa, hpa, kpa, bar, mbar, atm, psi, mmhg).",
                localizedDescriptionKey: "logo.doc.convertpressure",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "value", required: true, description: "The numeric pressure value.", example: "1"),
                    LogoPrimitiveParameter(name: "fromUnit", required: true, description: "Source pressure unit.", example: "atm", allowedValues: pressureUnits),
                    LogoPrimitiveParameter(name: "toUnit", required: true, description: "Target pressure unit.", example: "psi", allowedValues: pressureUnits),
                ],
                examples: [LogoPrimitiveExample(input: "CONVERT.PRESSURE 1 \"atm \"psi", output: "14.695948776")]
            )

        case .convertAcceleration:
            let accelerationUnits = ["m/s2", "g"]
            return LogoPrimitiveMeta(
                name: "CONVERT.ACCELERATION",
                description: "Converts acceleration measurements between units (m/s2, g).",
                localizedDescriptionKey: "logo.doc.convertacceleration",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "value", required: true, description: "The numeric acceleration value.", example: "1"),
                    LogoPrimitiveParameter(name: "fromUnit", required: true, description: "Source acceleration unit.", example: "g", allowedValues: accelerationUnits),
                    LogoPrimitiveParameter(name: "toUnit", required: true, description: "Target acceleration unit.", example: "m/s2", allowedValues: accelerationUnits),
                ],
                examples: [LogoPrimitiveExample(input: "CONVERT.ACCELERATION 1 \"g \"m/s2", output: "9.81")]
            )

        case .convertDuration:
            let durationUnits = ["s", "min", "hr", "ms", "us", "ns", "ps"]
            return LogoPrimitiveMeta(
                name: "CONVERT.DURATION",
                description: "Converts time durations between units (s, min, hr, ms, us, ns, ps).",
                localizedDescriptionKey: "logo.doc.convertduration",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "value", required: true, description: "The numeric duration value.", example: "2"),
                    LogoPrimitiveParameter(name: "fromUnit", required: true, description: "Source duration unit.", example: "hr", allowedValues: durationUnits),
                    LogoPrimitiveParameter(name: "toUnit", required: true, description: "Target duration unit.", example: "min", allowedValues: durationUnits),
                ],
                examples: [LogoPrimitiveExample(input: "CONVERT.DURATION 2 \"hr \"min", output: "120")]
            )

        case .convertFrequency:
            let frequencyUnits = ["hz", "khz", "mhz", "ghz", "thz", "fps"]
            return LogoPrimitiveMeta(
                name: "CONVERT.FREQUENCY",
                description: "Converts frequency measurements between units (hz, khz, mhz, ghz, thz, fps).",
                localizedDescriptionKey: "logo.doc.convertfrequency",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "value", required: true, description: "The numeric frequency value.", example: "1"),
                    LogoPrimitiveParameter(name: "fromUnit", required: true, description: "Source frequency unit.", example: "ghz", allowedValues: frequencyUnits),
                    LogoPrimitiveParameter(name: "toUnit", required: true, description: "Target frequency unit.", example: "mhz", allowedValues: frequencyUnits),
                ],
                examples: [LogoPrimitiveExample(input: "CONVERT.FREQUENCY 1 \"ghz \"mhz", output: "1000")]
            )

        case .convertSpeed:
            let speedUnits = ["m/s", "km/h", "kmh", "mph", "knots"]
            return LogoPrimitiveMeta(
                name: "CONVERT.SPEED",
                description: "Converts speed measurements between units (m/s, kmh, mph, knots).",
                localizedDescriptionKey: "logo.doc.convertspeed",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "value", required: true, description: "The numeric speed value.", example: "100"),
                    LogoPrimitiveParameter(name: "fromUnit", required: true, description: "Source speed unit.", example: "kmh", allowedValues: speedUnits),
                    LogoPrimitiveParameter(name: "toUnit", required: true, description: "Target speed unit.", example: "mph", allowedValues: speedUnits),
                ],
                examples: [LogoPrimitiveExample(input: "CONVERT.SPEED 100 \"kmh \"mph", output: "62.137119224")]
            )

        case .convertEnergy:
            let energyUnits = ["j", "kj", "mj", "gj", "cal", "kcal", "kwh"]
            return LogoPrimitiveMeta(
                name: "CONVERT.ENERGY",
                description: "Converts energy measurements between units (j, kj, cal, kcal, kwh).",
                localizedDescriptionKey: "logo.doc.convertenergy",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "value", required: true, description: "The numeric energy value.", example: "1"),
                    LogoPrimitiveParameter(name: "fromUnit", required: true, description: "Source energy unit.", example: "kwh", allowedValues: energyUnits),
                    LogoPrimitiveParameter(name: "toUnit", required: true, description: "Target energy unit.", example: "j", allowedValues: energyUnits),
                ],
                examples: [LogoPrimitiveExample(input: "CONVERT.ENERGY 1 \"kwh \"j", output: "3600000")]
            )

        case .convertPower:
            let powerUnits = ["w", "mw", "kw", "megawatt", "gw", "tw", "hp"]
            return LogoPrimitiveMeta(
                name: "CONVERT.POWER",
                description: "Converts power measurements between units (w, kw, mw, gw, hp).",
                localizedDescriptionKey: "logo.doc.convertpower",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "value", required: true, description: "The numeric power value.", example: "1"),
                    LogoPrimitiveParameter(name: "fromUnit", required: true, description: "Source power unit.", example: "hp", allowedValues: powerUnits),
                    LogoPrimitiveParameter(name: "toUnit", required: true, description: "Target power unit.", example: "w", allowedValues: powerUnits),
                ],
                examples: [LogoPrimitiveExample(input: "CONVERT.POWER 1 \"hp \"w", output: "745.699871582")]
            )

        case .convertTemperature:
            let temperatureUnits = ["c", "f", "k"]
            return LogoPrimitiveMeta(
                name: "CONVERT.TEMPERATURE",
                description: "Converts temperature measurements between units (c, f, k).",
                localizedDescriptionKey: "logo.doc.converttemperature",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "value", required: true, description: "The numeric temperature value.", example: "100"),
                    LogoPrimitiveParameter(name: "fromUnit", required: true, description: "Source temperature unit (c, f, k).", example: "c", allowedValues: temperatureUnits),
                    LogoPrimitiveParameter(name: "toUnit", required: true, description: "Target temperature unit (c, f, k).", example: "f", allowedValues: temperatureUnits),
                ],
                examples: [LogoPrimitiveExample(input: "CONVERT.TEMPERATURE 100 \"c \"f", output: "212")]
            )

        case .convertIlluminance:
            let illuminanceUnits = ["lx", "lux"]
            return LogoPrimitiveMeta(
                name: "CONVERT.ILLUMINANCE",
                description: "Converts illuminance measurements (lx).",
                localizedDescriptionKey: "logo.doc.convertilluminance",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "value", required: true, description: "The numeric illuminance value.", example: "100"),
                    LogoPrimitiveParameter(name: "fromUnit", required: true, description: "Source illuminance unit.", example: "lx", allowedValues: illuminanceUnits),
                    LogoPrimitiveParameter(name: "toUnit", required: true, description: "Target illuminance unit.", example: "lx", allowedValues: illuminanceUnits),
                ],
                examples: [LogoPrimitiveExample(input: "CONVERT.ILLUMINANCE 100 \"lx \"lx", output: "100")]
            )

        case .convertElectricCharge:
            let electricChargeUnits = ["c", "ah", "mah", "uah", "kiloamperehour", "megaamperehour"]
            return LogoPrimitiveMeta(
                name: "CONVERT.ELECTRICCHARGE",
                description: "Converts electric charge measurements between units (c, ah, mah, uah).",
                localizedDescriptionKey: "logo.doc.convertelectriccharge",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "value", required: true, description: "The numeric electric charge value.", example: "5000"),
                    LogoPrimitiveParameter(name: "fromUnit", required: true, description: "Source charge unit.", example: "mah", allowedValues: electricChargeUnits),
                    LogoPrimitiveParameter(name: "toUnit", required: true, description: "Target charge unit.", example: "ah", allowedValues: electricChargeUnits),
                ],
                examples: [LogoPrimitiveExample(input: "CONVERT.ELECTRICCHARGE 5000 \"mah \"ah", output: "5")]
            )

        case .convertElectricCurrent:
            let electricCurrentUnits = ["a", "ma", "ua", "ka", "megaamp"]
            return LogoPrimitiveMeta(
                name: "CONVERT.ELECTRICCURRENT",
                description: "Converts electric current measurements between units (a, ma, ua, ka).",
                localizedDescriptionKey: "logo.doc.convertelectriccurrent",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "value", required: true, description: "The numeric electric current value.", example: "1.5"),
                    LogoPrimitiveParameter(name: "fromUnit", required: true, description: "Source current unit.", example: "a", allowedValues: electricCurrentUnits),
                    LogoPrimitiveParameter(name: "toUnit", required: true, description: "Target current unit.", example: "ma", allowedValues: electricCurrentUnits),
                ],
                examples: [LogoPrimitiveExample(input: "CONVERT.ELECTRICCURRENT 1.5 \"a \"ma", output: "1500")]
            )

        case .convertElectricPotentialDifference:
            let electricPotentialUnits = ["v", "mv", "uv", "kv", "megavolt"]
            return LogoPrimitiveMeta(
                name: "CONVERT.ELECTRICPOTENTIALDIFFERENCE",
                description: "Converts voltage / electric potential difference measurements between units (v, mv, uv, kv, megavolt).",
                localizedDescriptionKey: "logo.doc.convertelectricpotentialdifference",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "value", required: true, description: "The numeric voltage value.", example: "5"),
                    LogoPrimitiveParameter(name: "fromUnit", required: true, description: "Source voltage unit.", example: "v", allowedValues: electricPotentialUnits),
                    LogoPrimitiveParameter(name: "toUnit", required: true, description: "Target voltage unit.", example: "mv", allowedValues: electricPotentialUnits),
                ],
                examples: [LogoPrimitiveExample(input: "CONVERT.ELECTRICPOTENTIALDIFFERENCE 5 \"v \"mv", output: "5000")]
            )

        case .convertElectricResistance:
            let electricResistanceUnits = ["ohm", "mohm", "uohm", "kohm", "megaohm"]
            return LogoPrimitiveMeta(
                name: "CONVERT.ELECTRICRESISTANCE",
                description: "Converts electric resistance measurements between units (ohm, kohm, megaohm, mohm).",
                localizedDescriptionKey: "logo.doc.convertelectricresistance",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "value", required: true, description: "The numeric resistance value.", example: "1"),
                    LogoPrimitiveParameter(name: "fromUnit", required: true, description: "Source resistance unit.", example: "kohm", allowedValues: electricResistanceUnits),
                    LogoPrimitiveParameter(name: "toUnit", required: true, description: "Target resistance unit.", example: "ohm", allowedValues: electricResistanceUnits),
                ],
                examples: [LogoPrimitiveExample(input: "CONVERT.ELECTRICRESISTANCE 1 \"kohm \"ohm", output: "1000")]
            )

        case .convertConcentrationMass:
            let concentrationMassUnits = ["g/l", "mg/dl", "mmol/l"]
            return LogoPrimitiveMeta(
                name: "CONVERT.CONCENTRATIONMASS",
                description: "Converts concentration mass measurements between units (g/l, mg/dl, mmol/l).",
                localizedDescriptionKey: "logo.doc.convertconcentrationmass",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "value", required: true, description: "The numeric concentration value.", example: "1"),
                    LogoPrimitiveParameter(name: "fromUnit", required: true, description: "Source concentration unit.", example: "g/l", allowedValues: concentrationMassUnits),
                    LogoPrimitiveParameter(name: "toUnit", required: true, description: "Target concentration unit.", example: "mg/dl", allowedValues: concentrationMassUnits),
                ],
                examples: [LogoPrimitiveExample(input: "CONVERT.CONCENTRATIONMASS 1 \"g/l \"mg/dl", output: "100")]
            )

        case .convertDispersion:
            let dispersionUnits = ["ppm"]
            return LogoPrimitiveMeta(
                name: "CONVERT.DISPERSION",
                description: "Converts dispersion measurements (ppm).",
                localizedDescriptionKey: "logo.doc.convertdispersion",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "value", required: true, description: "The numeric dispersion value.", example: "10"),
                    LogoPrimitiveParameter(name: "fromUnit", required: true, description: "Source dispersion unit.", example: "ppm", allowedValues: dispersionUnits),
                    LogoPrimitiveParameter(name: "toUnit", required: true, description: "Target dispersion unit.", example: "ppm", allowedValues: dispersionUnits),
                ],
                examples: [LogoPrimitiveExample(input: "CONVERT.DISPERSION 10 \"ppm \"ppm", output: "10")]
            )

        case .convertFuelEfficiency:
            let fuelEfficiencyUnits = ["l/100km", "mpg", "imperialmpg"]
            return LogoPrimitiveMeta(
                name: "CONVERT.FUELEFFICIENCY",
                description: "Converts fuel efficiency measurements between units (l/100km, mpg, imperial mpg).",
                localizedDescriptionKey: "logo.doc.convertfuelefficiency",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "value", required: true, description: "The numeric fuel efficiency value.", example: "30"),
                    LogoPrimitiveParameter(name: "fromUnit", required: true, description: "Source fuel efficiency unit.", example: "mpg", allowedValues: fuelEfficiencyUnits),
                    LogoPrimitiveParameter(name: "toUnit", required: true, description: "Target fuel efficiency unit.", example: "l/100km", allowedValues: fuelEfficiencyUnits),
                ],
                examples: [LogoPrimitiveExample(input: "CONVERT.FUELEFFICIENCY 30 \"mpg \"l/100km", output: "7.840487")]
            )

        case .convertInformationStorage:
            let infoStorageUnits = ["b", "kb", "mb", "gb", "tb", "pb", "eb", "zb", "yb", "bit", "kbit", "mbit", "gbit", "tbit", "pbit", "kib", "mib", "gib", "tib", "pib", "kibit", "mibit", "gibit"]
            return LogoPrimitiveMeta(
                name: "CONVERT.INFORMATIONSTORAGE",
                description: "Converts data storage and memory measurements between units (b, kb, mb, gb, tb, pb, bit, kbit, mbit, gbit, kib, mib, gib, tib).",
                localizedDescriptionKey: "logo.doc.convertinformationstorage",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "value", required: true, description: "The numeric data storage value.", example: "1"),
                    LogoPrimitiveParameter(name: "fromUnit", required: true, description: "Source data storage unit (b, kb, mb, gb, tb, kib, mib, gib).", example: "gb", allowedValues: infoStorageUnits),
                    LogoPrimitiveParameter(name: "toUnit", required: true, description: "Target data storage unit.", example: "mb", allowedValues: infoStorageUnits),
                ],
                examples: [LogoPrimitiveExample(input: "CONVERT.INFORMATIONSTORAGE 1 \"gb \"mb", output: "1000")]
            )

        // MARK: - FORMAT.* Measurement Metadata

        case .formatArea:
            let areaUnits = ["sqm", "m2", "sqkm", "km2", "sqcm", "cm2", "sqmm", "mm2", "squm", "sqnm", "sqin", "in2", "sqft", "ft2", "sqyd", "yd2", "sqmi", "mi2", "acre", "acres", "are", "ares", "ha", "hectares"]
            return LogoPrimitiveMeta(
                name: "FORMAT.AREA",
                description: "Formats area measurements into localized string with unit symbols or long names.",
                localizedDescriptionKey: "logo.doc.formatarea",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "value", required: true, description: "The numeric area value.", example: "100"),
                    LogoPrimitiveParameter(name: "unit", required: true, description: "Area unit.", example: "sqm", allowedValues: areaUnits),
                    LogoPrimitiveParameter(name: "style", required: false, description: "Unit display style.", example: "medium", allowedValues: ["medium", "short", "long"]),
                    LogoPrimitiveParameter(name: "locale", required: false, description: "Target locale.", example: "en_US"),
                    LogoPrimitiveParameter(name: "naturalScale", required: false, description: "Auto-scale unit to natural magnitude.", example: "true"),
                ],
                examples: [LogoPrimitiveExample(input: "FORMAT.AREA 100 \"sqm \"long \"zh_TW", output: "100 平方公尺")],
                notes: "Not supported on Linux or Windows."
            )

        case .formatLength:
            let lengthUnits = ["m", "km", "cm", "mm", "um", "nm", "pm", "dm", "dam", "hm", "in", "ft", "yd", "mi", "nmi", "furlong", "fathom", "ly", "pc", "au"]
            return LogoPrimitiveMeta(
                name: "FORMAT.LENGTH",
                description: "Formats length measurements into localized string with unit symbols or long names.",
                localizedDescriptionKey: "logo.doc.formatlength",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "value", required: true, description: "The numeric length value.", example: "1500"),
                    LogoPrimitiveParameter(name: "unit", required: true, description: "Length unit.", example: "m", allowedValues: lengthUnits),
                    LogoPrimitiveParameter(name: "style", required: false, description: "Unit display style.", example: "medium", allowedValues: ["medium", "short", "long"]),
                    LogoPrimitiveParameter(name: "locale", required: false, description: "Target locale.", example: "en_US"),
                    LogoPrimitiveParameter(name: "naturalScale", required: false, description: "Auto-scale unit to natural magnitude.", example: "true"),
                ],
                examples: [LogoPrimitiveExample(input: "FORMAT.LENGTH 1500 \"m \"long \"zh_TW \"true", output: "1.5 公里")],
                notes: "Not supported on Linux or Windows."
            )

        case .formatVolume:
            let volumeUnits = ["l", "ml", "cl", "dl", "kl", "m3", "km3", "cm3", "mm3", "in3", "ft3", "yd3", "mi3", "acrefeet", "bushel", "tsp", "tbsp", "floz", "cup", "pt", "qt", "gal", "imptsp", "imptbsp", "impfloz", "imppt", "impqt", "impgal"]
            return LogoPrimitiveMeta(
                name: "FORMAT.VOLUME",
                description: "Formats volume measurements into localized string with unit symbols or long names.",
                localizedDescriptionKey: "logo.doc.formatvolume",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "value", required: true, description: "The numeric volume value.", example: "2"),
                    LogoPrimitiveParameter(name: "unit", required: true, description: "Volume unit.", example: "l", allowedValues: volumeUnits),
                    LogoPrimitiveParameter(name: "style", required: false, description: "Unit display style.", example: "medium", allowedValues: ["medium", "short", "long"]),
                    LogoPrimitiveParameter(name: "locale", required: false, description: "Target locale.", example: "en_US"),
                    LogoPrimitiveParameter(name: "naturalScale", required: false, description: "Auto-scale unit to natural magnitude.", example: "true"),
                ],
                examples: [LogoPrimitiveExample(input: "FORMAT.VOLUME 2 \"l \"long \"zh_TW", output: "2 公升")],
                notes: "Not supported on Linux or Windows."
            )

        case .formatAngle:
            let angleUnits = ["deg", "rad", "grad", "rev", "arcmin", "arcsec"]
            return LogoPrimitiveMeta(
                name: "FORMAT.ANGLE",
                description: "Formats angle measurements into localized string with unit symbols or long names.",
                localizedDescriptionKey: "logo.doc.formatangle",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "value", required: true, description: "The numeric angle value.", example: "90"),
                    LogoPrimitiveParameter(name: "unit", required: true, description: "Angle unit.", example: "deg", allowedValues: angleUnits),
                    LogoPrimitiveParameter(name: "style", required: false, description: "Unit display style.", example: "medium", allowedValues: ["medium", "short", "long"]),
                    LogoPrimitiveParameter(name: "locale", required: false, description: "Target locale.", example: "en_US"),
                    LogoPrimitiveParameter(name: "naturalScale", required: false, description: "Auto-scale unit to natural magnitude.", example: "true"),
                ],
                examples: [LogoPrimitiveExample(input: "FORMAT.ANGLE 90 \"deg \"short", output: "90°")],
                notes: "Not supported on Linux or Windows."
            )

        case .formatMass:
            let massUnits = ["kg", "g", "mg", "ug", "ng", "pg", "t", "lb", "oz", "ozt", "ct", "st", "ston", "slug"]
            return LogoPrimitiveMeta(
                name: "FORMAT.MASS",
                description: "Formats mass/weight measurements into localized string with unit symbols or long names.",
                localizedDescriptionKey: "logo.doc.formatmass",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "value", required: true, description: "The numeric mass value.", example: "500"),
                    LogoPrimitiveParameter(name: "unit", required: true, description: "Mass unit.", example: "g", allowedValues: massUnits),
                    LogoPrimitiveParameter(name: "style", required: false, description: "Unit display style.", example: "medium", allowedValues: ["medium", "short", "long"]),
                    LogoPrimitiveParameter(name: "locale", required: false, description: "Target locale.", example: "en_US"),
                    LogoPrimitiveParameter(name: "naturalScale", required: false, description: "Auto-scale unit to natural magnitude.", example: "true"),
                ],
                examples: [LogoPrimitiveExample(input: "FORMAT.MASS 500 \"g \"long \"zh_TW", output: "500 公克")],
                notes: "Not supported on Linux or Windows."
            )

        case .formatPressure:
            let pressureUnits = ["pa", "hpa", "kpa", "mpa", "gpa", "bar", "mbar", "atm", "mmhg", "torr", "inhg", "psi"]
            return LogoPrimitiveMeta(
                name: "FORMAT.PRESSURE",
                description: "Formats pressure measurements into localized string with unit symbols or long names.",
                localizedDescriptionKey: "logo.doc.formatpressure",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "value", required: true, description: "The numeric pressure value.", example: "1"),
                    LogoPrimitiveParameter(name: "unit", required: true, description: "Pressure unit.", example: "atm", allowedValues: pressureUnits),
                    LogoPrimitiveParameter(name: "style", required: false, description: "Unit display style.", example: "medium", allowedValues: ["medium", "short", "long"]),
                    LogoPrimitiveParameter(name: "locale", required: false, description: "Target locale.", example: "en_US"),
                    LogoPrimitiveParameter(name: "naturalScale", required: false, description: "Auto-scale unit to natural magnitude.", example: "true"),
                ],
                examples: [LogoPrimitiveExample(input: "FORMAT.PRESSURE 1 \"atm \"short", output: "1 atm")],
                notes: "Not supported on Linux or Windows."
            )

        case .formatAcceleration:
            let accelerationUnits = ["m/s2", "g"]
            return LogoPrimitiveMeta(
                name: "FORMAT.ACCELERATION",
                description: "Formats acceleration measurements into localized string with unit symbols or long names.",
                localizedDescriptionKey: "logo.doc.formatacceleration",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "value", required: true, description: "The numeric acceleration value.", example: "9.81"),
                    LogoPrimitiveParameter(name: "unit", required: true, description: "Acceleration unit.", example: "m/s2", allowedValues: accelerationUnits),
                    LogoPrimitiveParameter(name: "style", required: false, description: "Unit display style.", example: "medium", allowedValues: ["medium", "short", "long"]),
                    LogoPrimitiveParameter(name: "locale", required: false, description: "Target locale.", example: "en_US"),
                    LogoPrimitiveParameter(name: "naturalScale", required: false, description: "Auto-scale unit to natural magnitude.", example: "true"),
                ],
                examples: [LogoPrimitiveExample(input: "FORMAT.ACCELERATION 9.81 \"m/s2 \"medium", output: "9.81 m/s²")],
                notes: "Not supported on Linux or Windows."
            )

        case .formatDuration:
            let durationUnits = ["s", "min", "hr", "ms", "us", "ns", "ps"]
            return LogoPrimitiveMeta(
                name: "FORMAT.DURATION",
                description: "Formats time duration measurements into localized string with unit symbols or long names.",
                localizedDescriptionKey: "logo.doc.formatduration",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "value", required: true, description: "The numeric duration value.", example: "2"),
                    LogoPrimitiveParameter(name: "unit", required: true, description: "Duration unit.", example: "hr", allowedValues: durationUnits),
                    LogoPrimitiveParameter(name: "style", required: false, description: "Unit display style.", example: "medium", allowedValues: ["medium", "short", "long"]),
                    LogoPrimitiveParameter(name: "locale", required: false, description: "Target locale.", example: "en_US"),
                    LogoPrimitiveParameter(name: "naturalScale", required: false, description: "Auto-scale unit to natural magnitude.", example: "true"),
                ],
                examples: [LogoPrimitiveExample(input: "FORMAT.DURATION 2 \"hr \"long \"zh_TW", output: "2 小時")],
                notes: "Not supported on Linux or Windows."
            )

        case .formatFrequency:
            let frequencyUnits = ["hz", "khz", "mhz", "ghz", "thz", "fps"]
            return LogoPrimitiveMeta(
                name: "FORMAT.FREQUENCY",
                description: "Formats frequency measurements into localized string with unit symbols or long names.",
                localizedDescriptionKey: "logo.doc.formatfrequency",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "value", required: true, description: "The numeric frequency value.", example: "60"),
                    LogoPrimitiveParameter(name: "unit", required: true, description: "Frequency unit.", example: "hz", allowedValues: frequencyUnits),
                    LogoPrimitiveParameter(name: "style", required: false, description: "Unit display style.", example: "medium", allowedValues: ["medium", "short", "long"]),
                    LogoPrimitiveParameter(name: "locale", required: false, description: "Target locale.", example: "en_US"),
                    LogoPrimitiveParameter(name: "naturalScale", required: false, description: "Auto-scale unit to natural magnitude.", example: "true"),
                ],
                examples: [LogoPrimitiveExample(input: "FORMAT.FREQUENCY 60 \"hz \"short", output: "60 Hz")],
                notes: "Not supported on Linux or Windows."
            )

        case .formatSpeed:
            let speedUnits = ["m/s", "km/h", "kmh", "mph", "knots"]
            return LogoPrimitiveMeta(
                name: "FORMAT.SPEED",
                description: "Formats speed measurements into localized string with unit symbols or long names.",
                localizedDescriptionKey: "logo.doc.formatspeed",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "value", required: true, description: "The numeric speed value.", example: "100"),
                    LogoPrimitiveParameter(name: "unit", required: true, description: "Speed unit.", example: "kmh", allowedValues: speedUnits),
                    LogoPrimitiveParameter(name: "style", required: false, description: "Unit display style.", example: "medium", allowedValues: ["medium", "short", "long"]),
                    LogoPrimitiveParameter(name: "locale", required: false, description: "Target locale.", example: "en_US"),
                    LogoPrimitiveParameter(name: "naturalScale", required: false, description: "Auto-scale unit to natural magnitude.", example: "true"),
                ],
                examples: [LogoPrimitiveExample(input: "FORMAT.SPEED 100 \"kmh \"long \"zh_TW", output: "100 公里/小時")],
                notes: "Not supported on Linux or Windows."
            )

        case .formatEnergy:
            let energyUnits = ["j", "kj", "mj", "gj", "cal", "kcal", "kwh"]
            return LogoPrimitiveMeta(
                name: "FORMAT.ENERGY",
                description: "Formats energy measurements into localized string with unit symbols or long names.",
                localizedDescriptionKey: "logo.doc.formatenergy",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "value", required: true, description: "The numeric energy value.", example: "2000"),
                    LogoPrimitiveParameter(name: "unit", required: true, description: "Energy unit.", example: "kcal", allowedValues: energyUnits),
                    LogoPrimitiveParameter(name: "style", required: false, description: "Unit display style.", example: "medium", allowedValues: ["medium", "short", "long"]),
                    LogoPrimitiveParameter(name: "locale", required: false, description: "Target locale.", example: "en_US"),
                    LogoPrimitiveParameter(name: "naturalScale", required: false, description: "Auto-scale unit to natural magnitude.", example: "true"),
                ],
                examples: [LogoPrimitiveExample(input: "FORMAT.ENERGY 2000 \"kcal \"long \"zh_TW", output: "2,000 大卡")],
                notes: "Not supported on Linux or Windows."
            )

        case .formatPower:
            let powerUnits = ["w", "mw", "kw", "megawatt", "gw", "tw", "hp"]
            return LogoPrimitiveMeta(
                name: "FORMAT.POWER",
                description: "Formats power measurements into localized string with unit symbols or long names.",
                localizedDescriptionKey: "logo.doc.formatpower",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "value", required: true, description: "The numeric power value.", example: "100"),
                    LogoPrimitiveParameter(name: "unit", required: true, description: "Power unit.", example: "kw", allowedValues: powerUnits),
                    LogoPrimitiveParameter(name: "style", required: false, description: "Unit display style.", example: "medium", allowedValues: ["medium", "short", "long"]),
                    LogoPrimitiveParameter(name: "locale", required: false, description: "Target locale.", example: "en_US"),
                    LogoPrimitiveParameter(name: "naturalScale", required: false, description: "Auto-scale unit to natural magnitude.", example: "true"),
                ],
                examples: [LogoPrimitiveExample(input: "FORMAT.POWER 100 \"kw \"long \"zh_TW", output: "100 瓩")],
                notes: "Not supported on Linux or Windows."
            )

        case .formatTemperature:
            let temperatureUnits = ["c", "f", "k"]
            return LogoPrimitiveMeta(
                name: "FORMAT.TEMPERATURE",
                description: "Formats temperature measurements into localized string with unit symbols or long names.",
                localizedDescriptionKey: "logo.doc.formattemperature",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "value", required: true, description: "The numeric temperature value.", example: "25"),
                    LogoPrimitiveParameter(name: "unit", required: true, description: "Temperature unit (c, f, k).", example: "c", allowedValues: temperatureUnits),
                    LogoPrimitiveParameter(name: "style", required: false, description: "Unit display style.", example: "medium", allowedValues: ["medium", "short", "long"]),
                    LogoPrimitiveParameter(name: "locale", required: false, description: "Target locale.", example: "en_US"),
                    LogoPrimitiveParameter(name: "naturalScale", required: false, description: "Auto-scale unit to natural magnitude.", example: "true"),
                ],
                examples: [LogoPrimitiveExample(input: "FORMAT.TEMPERATURE 25 \"c \"long \"zh_TW", output: "25 攝氏度")],
                notes: "Not supported on Linux or Windows."
            )

        case .formatIlluminance:
            let illuminanceUnits = ["lx", "lux"]
            return LogoPrimitiveMeta(
                name: "FORMAT.ILLUMINANCE",
                description: "Formats illuminance measurements into localized string with unit symbols or long names.",
                localizedDescriptionKey: "logo.doc.formatilluminance",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "value", required: true, description: "The numeric illuminance value.", example: "500"),
                    LogoPrimitiveParameter(name: "unit", required: true, description: "Illuminance unit.", example: "lx", allowedValues: illuminanceUnits),
                    LogoPrimitiveParameter(name: "style", required: false, description: "Unit display style.", example: "medium", allowedValues: ["medium", "short", "long"]),
                    LogoPrimitiveParameter(name: "locale", required: false, description: "Target locale.", example: "en_US"),
                    LogoPrimitiveParameter(name: "naturalScale", required: false, description: "Auto-scale unit to natural magnitude.", example: "true"),
                ],
                examples: [LogoPrimitiveExample(input: "FORMAT.ILLUMINANCE 500 \"lx \"short", output: "500 lx")],
                notes: "Not supported on Linux or Windows."
            )

        case .formatElectricCharge:
            let electricChargeUnits = ["c", "ah", "mah", "uah", "kiloamperehour", "megaamperehour"]
            return LogoPrimitiveMeta(
                name: "FORMAT.ELECTRICCHARGE",
                description: "Formats electric charge measurements into localized string with unit symbols or long names.",
                localizedDescriptionKey: "logo.doc.formatelectriccharge",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "value", required: true, description: "The numeric electric charge value.", example: "5000"),
                    LogoPrimitiveParameter(name: "unit", required: true, description: "Charge unit.", example: "mah", allowedValues: electricChargeUnits),
                    LogoPrimitiveParameter(name: "style", required: false, description: "Unit display style.", example: "medium", allowedValues: ["medium", "short", "long"]),
                    LogoPrimitiveParameter(name: "locale", required: false, description: "Target locale.", example: "en_US"),
                    LogoPrimitiveParameter(name: "naturalScale", required: false, description: "Auto-scale unit to natural magnitude.", example: "true"),
                ],
                examples: [LogoPrimitiveExample(input: "FORMAT.ELECTRICCHARGE 5000 \"mah \"short", output: "5,000 mAh")],
                notes: "Not supported on Linux or Windows."
            )

        case .formatElectricCurrent:
            let electricCurrentUnits = ["a", "ma", "ua", "ka", "megaamp"]
            return LogoPrimitiveMeta(
                name: "FORMAT.ELECTRICCURRENT",
                description: "Formats electric current measurements into localized string with unit symbols or long names.",
                localizedDescriptionKey: "logo.doc.formatelectriccurrent",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "value", required: true, description: "The numeric electric current value.", example: "2"),
                    LogoPrimitiveParameter(name: "unit", required: true, description: "Current unit.", example: "a", allowedValues: electricCurrentUnits),
                    LogoPrimitiveParameter(name: "style", required: false, description: "Unit display style.", example: "medium", allowedValues: ["medium", "short", "long"]),
                    LogoPrimitiveParameter(name: "locale", required: false, description: "Target locale.", example: "en_US"),
                    LogoPrimitiveParameter(name: "naturalScale", required: false, description: "Auto-scale unit to natural magnitude.", example: "true"),
                ],
                examples: [LogoPrimitiveExample(input: "FORMAT.ELECTRICCURRENT 2 \"a \"long \"zh_TW", output: "2 安培")],
                notes: "Not supported on Linux or Windows."
            )

        case .formatElectricPotentialDifference:
            let electricPotentialUnits = ["v", "mv", "uv", "kv", "megavolt"]
            return LogoPrimitiveMeta(
                name: "FORMAT.ELECTRICPOTENTIALDIFFERENCE",
                description: "Formats voltage / electric potential difference measurements into localized string with unit symbols or long names.",
                localizedDescriptionKey: "logo.doc.formatelectricpotentialdifference",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "value", required: true, description: "The numeric voltage value.", example: "110"),
                    LogoPrimitiveParameter(name: "unit", required: true, description: "Voltage unit.", example: "v", allowedValues: electricPotentialUnits),
                    LogoPrimitiveParameter(name: "style", required: false, description: "Unit display style.", example: "medium", allowedValues: ["medium", "short", "long"]),
                    LogoPrimitiveParameter(name: "locale", required: false, description: "Target locale.", example: "en_US"),
                    LogoPrimitiveParameter(name: "naturalScale", required: false, description: "Auto-scale unit to natural magnitude.", example: "true"),
                ],
                examples: [LogoPrimitiveExample(input: "FORMAT.VOLTAGE 110 \"v \"long \"zh_TW", output: "110 伏特")],
                notes: "Not supported on Linux or Windows."
            )

        case .formatElectricResistance:
            let electricResistanceUnits = ["ohm", "mohm", "uohm", "kohm", "megaohm"]
            return LogoPrimitiveMeta(
                name: "FORMAT.ELECTRICRESISTANCE",
                description: "Formats electric resistance measurements into localized string with unit symbols or long names.",
                localizedDescriptionKey: "logo.doc.formatelectricresistance",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "value", required: true, description: "The numeric resistance value.", example: "10"),
                    LogoPrimitiveParameter(name: "unit", required: true, description: "Resistance unit.", example: "kohm", allowedValues: electricResistanceUnits),
                    LogoPrimitiveParameter(name: "style", required: false, description: "Unit display style.", example: "medium", allowedValues: ["medium", "short", "long"]),
                    LogoPrimitiveParameter(name: "locale", required: false, description: "Target locale.", example: "en_US"),
                    LogoPrimitiveParameter(name: "naturalScale", required: false, description: "Auto-scale unit to natural magnitude.", example: "true"),
                ],
                examples: [LogoPrimitiveExample(input: "FORMAT.ELECTRICRESISTANCE 10 \"kohm \"long \"zh_TW", output: "10 千歐")],
                notes: "Not supported on Linux or Windows."
            )

        case .formatConcentrationMass:
            let concentrationMassUnits = ["g/l", "mg/dl", "mmol/l"]
            return LogoPrimitiveMeta(
                name: "FORMAT.CONCENTRATIONMASS",
                description: "Formats mass concentration measurements into localized string with unit symbols or long names.",
                localizedDescriptionKey: "logo.doc.formatconcentrationmass",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "value", required: true, description: "The numeric concentration value.", example: "100"),
                    LogoPrimitiveParameter(name: "unit", required: true, description: "Concentration unit.", example: "mg/dl", allowedValues: concentrationMassUnits),
                    LogoPrimitiveParameter(name: "style", required: false, description: "Unit display style.", example: "medium", allowedValues: ["medium", "short", "long"]),
                    LogoPrimitiveParameter(name: "locale", required: false, description: "Target locale.", example: "en_US"),
                    LogoPrimitiveParameter(name: "naturalScale", required: false, description: "Auto-scale unit to natural magnitude.", example: "true"),
                ],
                examples: [LogoPrimitiveExample(input: "FORMAT.CONCENTRATIONMASS 100 \"mg/dl \"short", output: "100 mg/dL")],
                notes: "Not supported on Linux or Windows."
            )

        case .formatDispersion:
            let dispersionUnits = ["ppm"]
            return LogoPrimitiveMeta(
                name: "FORMAT.DISPERSION",
                description: "Formats dispersion measurements into localized string with unit symbols or long names.",
                localizedDescriptionKey: "logo.doc.formatdispersion",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "value", required: true, description: "The numeric dispersion value.", example: "10"),
                    LogoPrimitiveParameter(name: "unit", required: true, description: "Dispersion unit.", example: "ppm", allowedValues: dispersionUnits),
                    LogoPrimitiveParameter(name: "style", required: false, description: "Unit display style.", example: "medium", allowedValues: ["medium", "short", "long"]),
                    LogoPrimitiveParameter(name: "locale", required: false, description: "Target locale.", example: "en_US"),
                    LogoPrimitiveParameter(name: "naturalScale", required: false, description: "Auto-scale unit to natural magnitude.", example: "true"),
                ],
                examples: [LogoPrimitiveExample(input: "FORMAT.DISPERSION 10 \"ppm \"short", output: "10 ppm")],
                notes: "Not supported on Linux or Windows."
            )

        case .formatFuelEfficiency:
            let fuelEfficiencyUnits = ["l/100km", "mpg", "imperialmpg"]
            return LogoPrimitiveMeta(
                name: "FORMAT.FUELEFFICIENCY",
                description: "Formats fuel efficiency measurements into localized string with unit symbols or long names.",
                localizedDescriptionKey: "logo.doc.formatfuelefficiency",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "value", required: true, description: "The numeric fuel efficiency value.", example: "30"),
                    LogoPrimitiveParameter(name: "unit", required: true, description: "Fuel efficiency unit.", example: "mpg", allowedValues: fuelEfficiencyUnits),
                    LogoPrimitiveParameter(name: "style", required: false, description: "Unit display style.", example: "medium", allowedValues: ["medium", "short", "long"]),
                    LogoPrimitiveParameter(name: "locale", required: false, description: "Target locale.", example: "en_US"),
                    LogoPrimitiveParameter(name: "naturalScale", required: false, description: "Auto-scale unit to natural magnitude.", example: "true"),
                ],
                examples: [LogoPrimitiveExample(input: "FORMAT.FUELEFFICIENCY 30 \"mpg \"short", output: "30 mpg")],
                notes: "Not supported on Linux or Windows."
            )

        case .formatInformationStorage:
            let infoStorageUnits = ["b", "kb", "mb", "gb", "tb", "pb", "eb", "zb", "yb", "bit", "kbit", "mbit", "gbit", "tbit", "pbit", "kib", "mib", "gib", "tib", "pib", "kibit", "mibit", "gibit"]
            return LogoPrimitiveMeta(
                name: "FORMAT.INFORMATIONSTORAGE",
                description: "Formats data storage measurements into localized string with unit symbols or long names.",
                localizedDescriptionKey: "logo.doc.formatinformationstorage",
                source: .zago,
                parameters: [
                    LogoPrimitiveParameter(name: "value", required: true, description: "The numeric data storage value.", example: "16"),
                    LogoPrimitiveParameter(name: "unit", required: true, description: "Storage unit.", example: "gb", allowedValues: infoStorageUnits),
                    LogoPrimitiveParameter(name: "style", required: false, description: "Unit display style.", example: "medium", allowedValues: ["medium", "short", "long"]),
                    LogoPrimitiveParameter(name: "locale", required: false, description: "Target locale.", example: "en_US"),
                    LogoPrimitiveParameter(name: "naturalScale", required: false, description: "Auto-scale unit to natural magnitude.", example: "true"),
                ],
                examples: [LogoPrimitiveExample(input: "FORMAT.STORAGE 16 \"gb \"long \"zh_TW", output: "16 GB")],
                notes: "Not supported on Linux or Windows."
            )

        default:
            return nil
        }
    }
}
