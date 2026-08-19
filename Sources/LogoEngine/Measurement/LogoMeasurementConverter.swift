import Foundation

/// Converter for physical measurements and units using Foundation's Measurement and Dimension system.
public enum LogoMeasurementConverter {
    public typealias DimensionKind = LogoDimensionKind

    public static func convert(value: Double, from fromUnitStr: String, to toUnitStr: String, kind: DimensionKind)
        -> Double?
    {
        let fromClean = normalizeUnitKey(fromUnitStr)
        let toClean = normalizeUnitKey(toUnitStr)

        switch kind {
        case .area:
            guard let from = areaUnits[fromClean], let to = areaUnits[toClean] else { return nil }
            return Measurement(value: value, unit: from).converted(to: to).value

        case .length:
            guard let from = lengthUnits[fromClean], let to = lengthUnits[toClean] else { return nil }
            return Measurement(value: value, unit: from).converted(to: to).value

        case .volume:
            guard let from = volumeUnits[fromClean], let to = volumeUnits[toClean] else { return nil }
            return Measurement(value: value, unit: from).converted(to: to).value

        case .angle:
            guard let from = angleUnits[fromClean], let to = angleUnits[toClean] else { return nil }
            return Measurement(value: value, unit: from).converted(to: to).value

        case .mass:
            guard let from = massUnits[fromClean], let to = massUnits[toClean] else { return nil }
            return Measurement(value: value, unit: from).converted(to: to).value

        case .pressure:
            guard let from = pressureUnits[fromClean], let to = pressureUnits[toClean] else { return nil }
            return Measurement(value: value, unit: from).converted(to: to).value

        case .acceleration:
            guard let from = accelerationUnits[fromClean], let to = accelerationUnits[toClean] else { return nil }
            return Measurement(value: value, unit: from).converted(to: to).value

        case .duration:
            guard let from = durationUnits[fromClean], let to = durationUnits[toClean] else { return nil }
            return Measurement(value: value, unit: from).converted(to: to).value

        case .frequency:
            guard let from = frequencyUnits[fromClean], let to = frequencyUnits[toClean] else { return nil }
            return Measurement(value: value, unit: from).converted(to: to).value

        case .speed:
            guard let from = speedUnits[fromClean], let to = speedUnits[toClean] else { return nil }
            return Measurement(value: value, unit: from).converted(to: to).value

        case .energy:
            guard let from = energyUnits[fromClean], let to = energyUnits[toClean] else { return nil }
            return Measurement(value: value, unit: from).converted(to: to).value

        case .power:
            guard let from = powerUnits[fromClean], let to = powerUnits[toClean] else { return nil }
            return Measurement(value: value, unit: from).converted(to: to).value

        case .temperature:
            guard let from = temperatureUnits[fromClean], let to = temperatureUnits[toClean] else { return nil }
            return Measurement(value: value, unit: from).converted(to: to).value

        case .illuminance:
            guard let from = illuminanceUnits[fromClean], let to = illuminanceUnits[toClean] else { return nil }
            return Measurement(value: value, unit: from).converted(to: to).value

        case .electricCharge:
            guard let from = electricChargeUnits[fromClean], let to = electricChargeUnits[toClean] else { return nil }
            return Measurement(value: value, unit: from).converted(to: to).value

        case .electricCurrent:
            guard let from = electricCurrentUnits[fromClean], let to = electricCurrentUnits[toClean] else { return nil }
            return Measurement(value: value, unit: from).converted(to: to).value

        case .electricPotentialDifference:
            guard let from = electricPotentialDifferenceUnits[fromClean],
                let to = electricPotentialDifferenceUnits[toClean]
            else { return nil }
            return Measurement(value: value, unit: from).converted(to: to).value

        case .electricResistance:
            guard let from = electricResistanceUnits[fromClean], let to = electricResistanceUnits[toClean] else {
                return nil
            }
            return Measurement(value: value, unit: from).converted(to: to).value

        case .concentrationMass:
            guard let from = concentrationMassUnits[fromClean], let to = concentrationMassUnits[toClean] else {
                return nil
            }
            return Measurement(value: value, unit: from).converted(to: to).value

        case .dispersion:
            guard let from = dispersionUnits[fromClean], let to = dispersionUnits[toClean] else { return nil }
            return Measurement(value: value, unit: from).converted(to: to).value

        case .fuelEfficiency:
            guard let from = fuelEfficiencyUnits[fromClean], let to = fuelEfficiencyUnits[toClean] else { return nil }
            return Measurement(value: value, unit: from).converted(to: to).value

        case .informationStorage:
            guard let from = informationStorageUnits[fromClean], let to = informationStorageUnits[toClean] else {
                return nil
            }
            return Measurement(value: value, unit: from).converted(to: to).value
        }
    }

    public static func findDimension(for unitStr: String) -> DimensionKind? {
        let clean = normalizeUnitKey(unitStr)
        if areaUnits[clean] != nil { return .area }
        if lengthUnits[clean] != nil { return .length }
        if volumeUnits[clean] != nil { return .volume }
        if angleUnits[clean] != nil { return .angle }
        if massUnits[clean] != nil { return .mass }
        if pressureUnits[clean] != nil { return .pressure }
        if accelerationUnits[clean] != nil { return .acceleration }
        if durationUnits[clean] != nil { return .duration }
        if frequencyUnits[clean] != nil { return .frequency }
        if speedUnits[clean] != nil { return .speed }
        if energyUnits[clean] != nil { return .energy }
        if powerUnits[clean] != nil { return .power }
        if temperatureUnits[clean] != nil { return .temperature }
        if illuminanceUnits[clean] != nil { return .illuminance }
        if electricChargeUnits[clean] != nil { return .electricCharge }
        if electricCurrentUnits[clean] != nil { return .electricCurrent }
        if electricPotentialDifferenceUnits[clean] != nil { return .electricPotentialDifference }
        if electricResistanceUnits[clean] != nil { return .electricResistance }
        if concentrationMassUnits[clean] != nil { return .concentrationMass }
        if dispersionUnits[clean] != nil { return .dispersion }
        if fuelEfficiencyUnits[clean] != nil { return .fuelEfficiency }
        if informationStorageUnits[clean] != nil { return .informationStorage }
        return nil
    }

    public static func convert(value: Double, from fromUnitStr: String, to toUnitStr: String) -> Double? {
        guard let kindFrom = findDimension(for: fromUnitStr),
            let kindTo = findDimension(for: toUnitStr),
            kindFrom == kindTo
        else {
            return nil
        }
        return convert(value: value, from: fromUnitStr, to: toUnitStr, kind: kindFrom)
    }

    public static func add(
        val1: Double, unit1: String,
        val2: Double, unit2: String,
        targetUnit: String? = nil
    ) -> (value: Double, unit: String, dimension: DimensionKind)? {
        guard let dim1 = findDimension(for: unit1),
            let dim2 = findDimension(for: unit2),
            dim1 == dim2
        else { return nil }
        let outUnit = targetUnit ?? unit1
        guard let dimOut = findDimension(for: outUnit), dimOut == dim1 else { return nil }
        guard let v1 = convert(value: val1, from: unit1, to: outUnit, kind: dim1),
            let v2 = convert(value: val2, from: unit2, to: outUnit, kind: dim1)
        else { return nil }
        return (v1 + v2, outUnit, dim1)
    }

    public static func subtract(
        val1: Double, unit1: String,
        val2: Double, unit2: String,
        targetUnit: String? = nil
    ) -> (value: Double, unit: String, dimension: DimensionKind)? {
        guard let dim1 = findDimension(for: unit1),
            let dim2 = findDimension(for: unit2),
            dim1 == dim2
        else { return nil }
        let outUnit = targetUnit ?? unit1
        guard let dimOut = findDimension(for: outUnit), dimOut == dim1 else { return nil }
        guard let v1 = convert(value: val1, from: unit1, to: outUnit, kind: dim1),
            let v2 = convert(value: val2, from: unit2, to: outUnit, kind: dim1)
        else { return nil }
        return (v1 - v2, outUnit, dim1)
    }

    public static func scale(
        value: Double, unit: String, factor: Double
    ) -> (value: Double, unit: String, dimension: DimensionKind)? {
        guard let dim = findDimension(for: unit) else { return nil }
        return (value * factor, unit, dim)
    }

    public static func compare(
        val1: Double, unit1: String,
        val2: Double, unit2: String
    ) -> (v1: Double, v2: Double)? {
        guard let dim1 = findDimension(for: unit1),
            let dim2 = findDimension(for: unit2),
            dim1 == dim2
        else { return nil }
        guard let v2InUnit1 = convert(value: val2, from: unit2, to: unit1, kind: dim1) else { return nil }
        return (val1, v2InUnit1)
    }

    public static func min(
        val1: Double, unit1: String,
        val2: Double, unit2: String,
        targetUnit: String? = nil
    ) -> (value: Double, unit: String, dimension: DimensionKind)? {
        guard let (v1, v2) = compare(val1: val1, unit1: unit1, val2: val2, unit2: unit2) else { return nil }
        let outUnit = targetUnit ?? unit1
        guard let dim = findDimension(for: unit1) else { return nil }
        let smaller = v1 <= v2 ? val1 : v2
        guard let result = convert(value: smaller, from: unit1, to: outUnit, kind: dim) else { return nil }
        return (result, outUnit, dim)
    }

    public static func max(
        val1: Double, unit1: String,
        val2: Double, unit2: String,
        targetUnit: String? = nil
    ) -> (value: Double, unit: String, dimension: DimensionKind)? {
        guard let (v1, v2) = compare(val1: val1, unit1: unit1, val2: val2, unit2: unit2) else { return nil }
        let outUnit = targetUnit ?? unit1
        guard let dim = findDimension(for: unit1) else { return nil }
        let greater = v1 >= v2 ? val1 : v2
        guard let result = convert(value: greater, from: unit1, to: outUnit, kind: dim) else { return nil }
        return (result, outUnit, dim)
    }

    public static func format(
        value: Double,
        unit unitStr: String,
        kind: DimensionKind,
        style styleStr: String? = nil,
        locale localeStr: String? = nil,
        naturalScale: Bool = false
    ) -> String? {
        #if os(Linux) || os(Windows)
            return nil
        #else
            let cleanUnit = normalizeUnitKey(unitStr)
            var resolvedStyle = styleStr
            var resolvedLocale = localeStr
            let resolvedNatural = naturalScale

            let cleanStyle = styleStr?.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: "\"':; "))
            if let cs = cleanStyle, !["short", "medium", "long", "full", "default", "s", "m", "l"].contains(cs) {
                if resolvedLocale == nil || resolvedLocale?.isEmpty == true {
                    resolvedLocale = styleStr
                    resolvedStyle = "medium"
                }
            }

            let formatter = MeasurementFormatter()
            if resolvedNatural {
                formatter.unitOptions = .naturalScale
            } else {
                formatter.unitOptions = .providedUnit
            }

            let unitStyle =
                (resolvedStyle?.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: "\"':; "))) ?? "medium"
            switch unitStyle {
            case "short", "s":
                formatter.unitStyle = .short
            case "long", "l", "full":
                formatter.unitStyle = .long
            default:
                formatter.unitStyle = .medium
            }

            formatter.locale = Locale(logoLocaleSpec: resolvedLocale)

            switch kind {
            case .area:
                guard let unit = areaUnits[cleanUnit] else { return nil }
                return formatter.string(from: Measurement(value: value, unit: unit))
            case .length:
                guard let unit = lengthUnits[cleanUnit] else { return nil }
                return formatter.string(from: Measurement(value: value, unit: unit))
            case .volume:
                guard let unit = volumeUnits[cleanUnit] else { return nil }
                return formatter.string(from: Measurement(value: value, unit: unit))
            case .angle:
                guard let unit = angleUnits[cleanUnit] else { return nil }
                return formatter.string(from: Measurement(value: value, unit: unit))
            case .mass:
                guard let unit = massUnits[cleanUnit] else { return nil }
                return formatter.string(from: Measurement(value: value, unit: unit))
            case .pressure:
                guard let unit = pressureUnits[cleanUnit] else { return nil }
                return formatter.string(from: Measurement(value: value, unit: unit))
            case .acceleration:
                guard let unit = accelerationUnits[cleanUnit] else { return nil }
                return formatter.string(from: Measurement(value: value, unit: unit))
            case .duration:
                guard let unit = durationUnits[cleanUnit] else { return nil }
                return formatter.string(from: Measurement(value: value, unit: unit))
            case .frequency:
                guard let unit = frequencyUnits[cleanUnit] else { return nil }
                return formatter.string(from: Measurement(value: value, unit: unit))
            case .speed:
                guard let unit = speedUnits[cleanUnit] else { return nil }
                return formatter.string(from: Measurement(value: value, unit: unit))
            case .energy:
                guard let unit = energyUnits[cleanUnit] else { return nil }
                return formatter.string(from: Measurement(value: value, unit: unit))
            case .power:
                guard let unit = powerUnits[cleanUnit] else { return nil }
                return formatter.string(from: Measurement(value: value, unit: unit))
            case .temperature:
                guard let unit = temperatureUnits[cleanUnit] else { return nil }
                return formatter.string(from: Measurement(value: value, unit: unit))
            case .illuminance:
                guard let unit = illuminanceUnits[cleanUnit] else { return nil }
                return formatter.string(from: Measurement(value: value, unit: unit))
            case .electricCharge:
                guard let unit = electricChargeUnits[cleanUnit] else { return nil }
                return formatter.string(from: Measurement(value: value, unit: unit))
            case .electricCurrent:
                guard let unit = electricCurrentUnits[cleanUnit] else { return nil }
                return formatter.string(from: Measurement(value: value, unit: unit))
            case .electricPotentialDifference:
                guard let unit = electricPotentialDifferenceUnits[cleanUnit] else { return nil }
                return formatter.string(from: Measurement(value: value, unit: unit))
            case .electricResistance:
                guard let unit = electricResistanceUnits[cleanUnit] else { return nil }
                return formatter.string(from: Measurement(value: value, unit: unit))
            case .concentrationMass:
                guard let unit = concentrationMassUnits[cleanUnit] else { return nil }
                return formatter.string(from: Measurement(value: value, unit: unit))
            case .dispersion:
                guard let unit = dispersionUnits[cleanUnit] else { return nil }
                return formatter.string(from: Measurement(value: value, unit: unit))
            case .fuelEfficiency:
                guard let unit = fuelEfficiencyUnits[cleanUnit] else { return nil }
                return formatter.string(from: Measurement(value: value, unit: unit))
            case .informationStorage:
                guard let unit = informationStorageUnits[cleanUnit] else { return nil }
                return formatter.string(from: Measurement(value: value, unit: unit))
            }
        #endif
    }

    public static func disambiguateFormatOptions(
        _ args: [String],
        style: inout String?,
        locale: inout String?,
        naturalScale: inout Bool
    ) {
        for arg in args {
            let clean = arg.trimmingCharacters(in: CharacterSet(charactersIn: "\"':; ")).trimmingCharacters(
                in: .whitespacesAndNewlines)
            if clean.isEmpty { continue }
            let lower = clean.lowercased()
            if ["true", "false", "yes", "no"].contains(lower) {
                naturalScale = (lower == "true" || lower == "yes")
            } else if ["short", "medium", "long", "full", "default", "s", "m", "l"].contains(lower) {
                style = lower
            } else {
                locale = clean
            }
        }
    }

    public static func formatResult(_ value: Double) -> String {
        if value.isNaN || value.isInfinite { return "\(value)" }
        let roundedInt = value.rounded()
        if abs(value - roundedInt) < 1e-5 && abs(roundedInt) < Double(Int64.max) {
            return "\(Int64(roundedInt))"
        }
        let rounded = (value * 1e9).rounded() / 1e9
        let intFromRounded = rounded.rounded()
        if abs(rounded - intFromRounded) < 1e-9 && abs(intFromRounded) < Double(Int64.max) {
            return "\(Int64(intFromRounded))"
        }
        return "\(rounded)"
    }

    internal static func normalizeUnitKey(_ s: String) -> String {
        var clean = s.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        clean = clean.trimmingCharacters(in: CharacterSet(charactersIn: "\"':;"))
        clean = clean.replacingOccurrences(of: " ", with: "")
        clean = clean.replacingOccurrences(of: "_", with: "")
        clean = clean.replacingOccurrences(of: "-", with: "")
        clean = clean.replacingOccurrences(of: "^", with: "")
        return clean
    }

    // MARK: - Unit Mappings

    private static let areaUnits: [String: UnitArea] = {
        var m: [String: UnitArea] = [:]
        func reg(_ unit: UnitArea, _ keys: [String]) {
            for k in keys { m[normalizeUnitKey(k)] = unit }
        }
        reg(.squareMeters, ["sqm", "m2", "squaremeter", "squaremeters", "squaremetres", "sqmeter", "sqmeters"])
        reg(.squareKilometers, ["sqkm", "km2", "squarekilometer", "squarekilometers", "sqkilometer", "sqkilometers"])
        reg(
            .squareCentimeters,
            ["sqcm", "cm2", "squarecentimeter", "squarecentimeters", "sqcentimeter", "sqcentimeters"])
        reg(
            .squareMillimeters,
            ["sqmm", "mm2", "squaremillimeter", "squaremillimeters", "sqmillimeter", "sqmillimeters"])
        reg(.squareMicrometers, ["squm", "um2", "squaremicrometer", "squaremicrometers"])
        reg(.squareNanometers, ["sqnm", "nm2", "squarenanometer", "squarenanometers"])
        reg(.squareInches, ["sqin", "in2", "squareinch", "squareinches", "sqinch", "sqinches"])
        reg(.squareFeet, ["sqft", "ft2", "squarefoot", "squarefeet", "sqfoot", "sqfeet"])
        reg(.squareYards, ["sqyd", "yd2", "squareyard", "squareyards", "sqyard", "sqyards"])
        reg(.squareMiles, ["sqmi", "mi2", "squaremile", "squaremiles", "sqmile", "sqmiles"])
        reg(.acres, ["ac", "acre", "acres"])
        reg(.ares, ["a", "are", "ares"])
        reg(.hectares, ["ha", "hectare", "hectares"])
        return m
    }()

    private static let lengthUnits: [String: UnitLength] = {
        var m: [String: UnitLength] = [:]
        func reg(_ unit: UnitLength, _ keys: [String]) {
            for k in keys { m[normalizeUnitKey(k)] = unit }
        }
        reg(.meters, ["m", "meter", "meters", "metre", "metres"])
        reg(.kilometers, ["km", "kilometer", "kilometers", "kilometre", "kilometres"])
        reg(.centimeters, ["cm", "centimeter", "centimeters", "centimetre", "centimetres"])
        reg(.millimeters, ["mm", "millimeter", "millimeters", "millimetre", "millimetres"])
        reg(.micrometers, ["um", "micrometer", "micrometers", "micron", "microns"])
        reg(.nanometers, ["nm", "nanometer", "nanometers"])
        reg(.picometers, ["pm", "picometer", "picometers"])
        reg(.decimeters, ["dm", "decimeter", "decimeters"])
        reg(.decameters, ["dam", "decameter", "decameters"])
        reg(.hectometers, ["hm", "hectometer", "hectometers"])
        reg(.megameters, ["megameter", "megameters"])
        reg(.inches, ["in", "inch", "inches"])
        reg(.feet, ["ft", "foot", "feet"])
        reg(.yards, ["yd", "yard", "yards"])
        reg(.miles, ["mi", "mile", "miles"])
        reg(.nauticalMiles, ["nmi", "nauticalmile", "nauticalmiles", "nmile", "nmiles"])
        reg(.furlongs, ["furlong", "furlongs", "fur"])
        reg(.fathoms, ["fathom", "fathoms", "ftm"])
        reg(.lightyears, ["ly", "lightyear", "lightyears"])
        reg(.parsecs, ["pc", "parsec", "parsecs"])
        reg(.astronomicalUnits, ["au", "astronomicalunit", "astronomicalunits"])
        reg(.scandinavianMiles, ["smi", "scandinavianmile", "scandinavianmiles"])
        return m
    }()

    private static let volumeUnits: [String: UnitVolume] = {
        var m: [String: UnitVolume] = [:]
        func reg(_ unit: UnitVolume, _ keys: [String]) {
            for k in keys { m[normalizeUnitKey(k)] = unit }
        }
        reg(.liters, ["l", "liter", "liters", "litre", "litres"])
        reg(.milliliters, ["ml", "milliliter", "milliliters", "millilitre", "millilitres", "cc"])
        reg(.centiliters, ["cl", "centiliter", "centiliters"])
        reg(.deciliters, ["dl", "deciliter", "deciliters"])
        reg(.kiloliters, ["kl", "kiloliter", "kiloliters"])
        reg(.megaliters, ["megaliter", "megaliters"])
        reg(.cubicMeters, ["m3", "cubicmeter", "cubicmeters", "cum", "cbm"])
        reg(.cubicKilometers, ["km3", "cubickilometer", "cubickilometers"])
        reg(.cubicCentimeters, ["cm3", "cubiccentimeter", "cubiccentimeters"])
        reg(.cubicMillimeters, ["mm3", "cubicmillimeter", "cubicmillimeters"])
        reg(.cubicInches, ["in3", "cuin", "cubicinch", "cubicinches"])
        reg(.cubicFeet, ["ft3", "cuft", "cubicfoot", "cubicfeet"])
        reg(.cubicYards, ["yd3", "cuyd", "cubicyard", "cubicyards"])
        reg(.cubicMiles, ["mi3", "cumi", "cubicmile", "cubicmiles"])
        reg(.acreFeet, ["acft", "acrefeet", "acrefoot"])
        reg(.bushels, ["bsh", "bu", "bushel", "bushels"])
        reg(.teaspoons, ["tsp", "teaspoon", "teaspoons"])
        reg(.tablespoons, ["tbsp", "tablespoon", "tablespoons"])
        reg(.fluidOunces, ["floz", "fluidounce", "fluidounces"])
        reg(.cups, ["cup", "cups"])
        reg(.pints, ["pt", "pint", "pints"])
        reg(.quarts, ["qt", "quart", "quarts"])
        reg(.gallons, ["gal", "gallon", "gallons"])
        reg(.imperialTeaspoons, ["imptsp", "imperialteaspoon", "imperialteaspoons"])
        reg(.imperialTablespoons, ["imptbsp", "imperialtablespoon", "imperialtablespoons"])
        reg(.imperialFluidOunces, ["impfloz", "imperialfluidounce", "imperialfluidounces"])
        reg(.imperialPints, ["imppt", "imperialpint", "imperialpints"])
        reg(.imperialQuarts, ["impqt", "imperialquart", "imperialquarts"])
        reg(.imperialGallons, ["impgal", "imperialgallon", "imperialgallons"])
        return m
    }()

    private static let angleUnits: [String: UnitAngle] = {
        var m: [String: UnitAngle] = [:]
        func reg(_ unit: UnitAngle, _ keys: [String]) {
            for k in keys { m[normalizeUnitKey(k)] = unit }
        }
        reg(.degrees, ["deg", "degree", "degrees", "°"])
        reg(.radians, ["rad", "radian", "radians"])
        reg(.gradians, ["grad", "gradian", "gradians", "gon"])
        reg(.revolutions, ["rev", "revolution", "revolutions", "turn", "turns"])
        reg(.arcMinutes, ["arcmin", "arcminute", "arcminutes", "amin"])
        reg(.arcSeconds, ["arcsec", "arcsecond", "arcseconds", "asec"])
        return m
    }()

    private static let massUnits: [String: UnitMass] = {
        var m: [String: UnitMass] = [:]
        func reg(_ unit: UnitMass, _ keys: [String]) {
            for k in keys { m[normalizeUnitKey(k)] = unit }
        }
        reg(.kilograms, ["kg", "kilogram", "kilograms", "kilo", "kilos"])
        reg(.grams, ["g", "gram", "grams"])
        reg(.milligrams, ["mg", "milligram", "milligrams"])
        reg(.micrograms, ["ug", "mcg", "microgram", "micrograms"])
        reg(.nanograms, ["ng", "nanogram", "nanograms"])
        reg(.picograms, ["pg", "picogram", "picograms"])
        reg(.metricTons, ["t", "ton", "tons", "tonne", "tonnes", "metricton", "metrictons"])
        reg(.pounds, ["lb", "lbs", "pound", "pounds"])
        reg(.ounces, ["oz", "ounce", "ounces"])
        reg(.ouncesTroy, ["ozt", "troyounce", "troyounces"])
        reg(.carats, ["ct", "carat", "carats"])
        reg(.stones, ["st", "stone", "stones"])
        reg(.shortTons, ["ston", "shortton", "shorttons", "uston"])
        reg(.slugs, ["slug", "slugs"])
        return m
    }()

    private static let pressureUnits: [String: UnitPressure] = {
        var m: [String: UnitPressure] = [:]
        func reg(_ unit: UnitPressure, _ keys: [String]) {
            for k in keys { m[normalizeUnitKey(k)] = unit }
        }
        reg(.newtonsPerMetersSquared, ["pa", "pascal", "pascals", "n/m2", "n/m^2"])
        reg(.hectopascals, ["hpa", "hectopascal", "hectopascals"])
        reg(.kilopascals, ["kpa", "kilopascal", "kilopascals"])
        reg(.megapascals, ["mpa", "megapascal", "megapascals"])
        reg(.gigapascals, ["gpa", "gigapascal", "gigapascals"])
        reg(.bars, ["bar", "bars"])
        reg(.millibars, ["mbar", "millibar", "millibars"])
        reg(
            UnitPressure(symbol: "atm", converter: UnitConverterLinear(coefficient: 101325)),
            ["atm", "atmosphere", "atmospheres"]
        )
        reg(.millimetersOfMercury, ["mmhg", "torr", "millimeterofmercury", "millimeterofmercurys"])
        reg(.inchesOfMercury, ["inhg", "inchofmercury", "inchesofmercury"])
        reg(.poundsForcePerSquareInch, ["psi", "poundspersquareinch", "poundforcepersquareinch"])
        return m
    }()

    private static let accelerationUnits: [String: UnitAcceleration] = {
        var m: [String: UnitAcceleration] = [:]
        func reg(_ unit: UnitAcceleration, _ keys: [String]) {
            for k in keys { m[normalizeUnitKey(k)] = unit }
        }
        reg(.metersPerSecondSquared, ["m/s2", "m/s^2", "mps2", "meterspersecondsquared", "meterpersecondsquared"])
        reg(.gravity, ["gforce", "g_force", "gee", "gravity", "g"])
        return m
    }()

    private static let durationUnits: [String: UnitDuration] = {
        var m: [String: UnitDuration] = [:]
        func reg(_ unit: UnitDuration, _ keys: [String]) {
            for k in keys { m[normalizeUnitKey(k)] = unit }
        }
        reg(.seconds, ["s", "sec", "secs", "second", "seconds"])
        reg(.minutes, ["min", "mins", "minute", "minutes"])
        reg(.hours, ["h", "hr", "hrs", "hour", "hours"])
        reg(.milliseconds, ["ms", "millisecond", "milliseconds"])
        reg(.microseconds, ["us", "microsecond", "microseconds"])
        reg(.nanoseconds, ["ns", "nanosecond", "nanoseconds"])
        reg(.picoseconds, ["ps", "picosecond", "picoseconds"])
        return m
    }()

    private static let frequencyUnits: [String: UnitFrequency] = {
        var m: [String: UnitFrequency] = [:]
        func reg(_ unit: UnitFrequency, _ keys: [String]) {
            for k in keys { m[normalizeUnitKey(k)] = unit }
        }
        reg(.hertz, ["hz", "hertz"])
        reg(.kilohertz, ["khz", "kilohertz"])
        reg(.megahertz, ["mhz", "megahertz"])
        reg(.gigahertz, ["ghz", "gigahertz"])
        reg(.terahertz, ["thz", "terahertz"])
        reg(.millihertz, ["millihertz"])
        reg(.microhertz, ["uhz", "microhertz"])
        reg(
            UnitFrequency(symbol: "fps", converter: UnitConverterLinear(coefficient: 1.0)),
            ["fps", "framespersecond"]
        )
        return m
    }()

    private static let speedUnits: [String: UnitSpeed] = {
        var m: [String: UnitSpeed] = [:]
        func reg(_ unit: UnitSpeed, _ keys: [String]) {
            for k in keys { m[normalizeUnitKey(k)] = unit }
        }
        reg(.metersPerSecond, ["m/s", "mps", "meterpersecond", "meterspersecond"])
        reg(.kilometersPerHour, ["km/h", "kmh", "kph", "kilometerperhour", "kilometersperhour"])
        reg(.milesPerHour, ["mph", "mi/h", "mileperhour", "milesperhour"])
        reg(.knots, ["kt", "kts", "knot", "knots"])
        return m
    }()

    private static let energyUnits: [String: UnitEnergy] = {
        var m: [String: UnitEnergy] = [:]
        func reg(_ unit: UnitEnergy, _ keys: [String]) {
            for k in keys { m[normalizeUnitKey(k)] = unit }
        }
        reg(.joules, ["j", "joule", "joules"])
        reg(.kilojoules, ["kj", "kilojoule", "kilojoules"])
        reg(
            UnitEnergy(symbol: "MJ", converter: UnitConverterLinear(coefficient: 1_000_000)),
            ["megajoule", "megajoules", "mj"]
        )
        reg(
            UnitEnergy(symbol: "GJ", converter: UnitConverterLinear(coefficient: 1_000_000_000)),
            ["gj", "gigajoule", "gigajoules"]
        )
        reg(.calories, ["cal", "calorie", "calories"])
        reg(.kilocalories, ["kcal", "kilocalorie", "kilocalories", "foodcalorie", "foodcalories"])
        reg(.kilowattHours, ["kwh", "kilowatthour", "kilowatthours"])
        return m
    }()

    private static let powerUnits: [String: UnitPower] = {
        var m: [String: UnitPower] = [:]
        func reg(_ unit: UnitPower, _ keys: [String]) {
            for k in keys { m[normalizeUnitKey(k)] = unit }
        }
        reg(.watts, ["w", "watt", "watts"])
        reg(.milliwatts, ["mw", "milliwatt", "milliwatts"])
        reg(.kilowatts, ["kw", "kilowatt", "kilowatts"])
        reg(.megawatts, ["megawatt", "megawatts"])
        reg(.gigawatts, ["gw", "gigawatt", "gigawatts"])
        reg(.terawatts, ["tw", "terawatt", "terawatts"])
        reg(.horsepower, ["hp", "horsepower"])
        reg(.femtowatts, ["fw", "femtowatt", "femtowatts"])
        reg(.picowatts, ["pw", "picowatt", "picowatts"])
        reg(.nanowatts, ["nw", "nanowatt", "nanowatts"])
        reg(.microwatts, ["uw", "microwatt", "microwatts"])
        return m
    }()

    private static let temperatureUnits: [String: UnitTemperature] = {
        var m: [String: UnitTemperature] = [:]
        func reg(_ unit: UnitTemperature, _ keys: [String]) {
            for k in keys { m[normalizeUnitKey(k)] = unit }
        }
        reg(.celsius, ["c", "celsius", "centigrade", "°c"])
        reg(.fahrenheit, ["f", "fahrenheit", "°f"])
        reg(.kelvin, ["k", "kelvin"])
        return m
    }()

    private static let illuminanceUnits: [String: UnitIlluminance] = {
        var m: [String: UnitIlluminance] = [:]
        func reg(_ unit: UnitIlluminance, _ keys: [String]) {
            for k in keys { m[normalizeUnitKey(k)] = unit }
        }
        reg(.lux, ["lx", "lux"])
        return m
    }()

    private static let electricChargeUnits: [String: UnitElectricCharge] = {
        var m: [String: UnitElectricCharge] = [:]
        func reg(_ unit: UnitElectricCharge, _ keys: [String]) {
            for k in keys { m[normalizeUnitKey(k)] = unit }
        }
        reg(.coulombs, ["c", "coulomb", "coulombs"])
        reg(.megaampereHours, ["megaamperehour", "megaamperehours"])
        reg(.kiloampereHours, ["kiloamperehour", "kiloamperehours"])
        reg(.ampereHours, ["ah", "amperehour", "amperehours"])
        reg(.milliampereHours, ["mah", "milliamperehour", "milliamperehours"])
        reg(.microampereHours, ["uah", "microamperehour", "microamperehours"])
        return m
    }()

    private static let electricCurrentUnits: [String: UnitElectricCurrent] = {
        var m: [String: UnitElectricCurrent] = [:]
        func reg(_ unit: UnitElectricCurrent, _ keys: [String]) {
            for k in keys { m[normalizeUnitKey(k)] = unit }
        }
        reg(.amperes, ["a", "amp", "amps", "ampere", "amperes"])
        reg(.milliamperes, ["ma", "milliamp", "milliamps", "milliampere", "milliamperes"])
        reg(.microamperes, ["ua", "microamp", "microamps", "microampere", "microamperes"])
        reg(.kiloamperes, ["ka", "kiloamp", "kiloamps", "kiloampere", "kiloamperes"])
        reg(.megaamperes, ["megaamp", "megaamps", "megaampere", "megaamperes"])
        return m
    }()

    private static let electricPotentialDifferenceUnits: [String: UnitElectricPotentialDifference] = {
        var m: [String: UnitElectricPotentialDifference] = [:]
        func reg(_ unit: UnitElectricPotentialDifference, _ keys: [String]) {
            for k in keys { m[normalizeUnitKey(k)] = unit }
        }
        reg(.volts, ["v", "volt", "volts"])
        reg(.millivolts, ["mv", "millivolt", "millivolts"])
        reg(.microvolts, ["uv", "microvolt", "microvolts"])
        reg(.kilovolts, ["kv", "kilovolt", "kilovolts"])
        reg(.megavolts, ["megavolt", "megavolts"])
        return m
    }()

    private static let electricResistanceUnits: [String: UnitElectricResistance] = {
        var m: [String: UnitElectricResistance] = [:]
        func reg(_ unit: UnitElectricResistance, _ keys: [String]) {
            for k in keys { m[normalizeUnitKey(k)] = unit }
        }
        reg(.ohms, ["ohm", "ohms", "Ω", "omega"])
        reg(.milliohms, ["mohm", "milliohm", "milliohms", "mΩ"])
        reg(.microohms, ["uohm", "microohm", "microohms", "µΩ"])
        reg(.kiloohms, ["kohm", "kiloohm", "kiloohms", "kΩ"])
        reg(.megaohms, ["megaohm", "megaohms", "MΩ"])
        return m
    }()

    private static let concentrationMassUnits: [String: UnitConcentrationMass] = {
        var m: [String: UnitConcentrationMass] = [:]
        func reg(_ unit: UnitConcentrationMass, _ keys: [String]) {
            for k in keys { m[normalizeUnitKey(k)] = unit }
        }
        reg(.gramsPerLiter, ["g/l", "g/L", "gramperliter", "gramsperliter"])
        reg(.milligramsPerDeciliter, ["mg/dl", "mg/dL", "milligramperdeciliter", "milligramsperdeciliter"])
        reg(
            .millimolesPerLiter(withGramsPerMole: 18.0182),
            ["mmol/l", "mmol/L", "millimoleperliter", "millimolesperliter"])
        return m
    }()

    private static let dispersionUnits: [String: UnitDispersion] = {
        var m: [String: UnitDispersion] = [:]
        func reg(_ unit: UnitDispersion, _ keys: [String]) {
            for k in keys { m[normalizeUnitKey(k)] = unit }
        }
        reg(.partsPerMillion, ["ppm", "partpermillion", "partspermillion"])
        return m
    }()

    private static let fuelEfficiencyUnits: [String: UnitFuelEfficiency] = {
        var m: [String: UnitFuelEfficiency] = [:]
        func reg(_ unit: UnitFuelEfficiency, _ keys: [String]) {
            for k in keys { m[normalizeUnitKey(k)] = unit }
        }
        reg(.litersPer100Kilometers, ["l/100km", "l100km", "literper100km", "litersper100kilometers"])
        reg(.milesPerGallon, ["mpg", "milepergallon", "milespergallon"])
        reg(.milesPerImperialGallon, ["imppmg", "imperialmpg", "milesperimperialgallon"])
        return m
    }()

    private static let informationStorageUnits: [String: UnitInformationStorage] = {
        var m: [String: UnitInformationStorage] = [:]
        func reg(_ unit: UnitInformationStorage, _ keys: [String]) {
            for k in keys { m[normalizeUnitKey(k)] = unit }
        }
        reg(.bytes, ["b", "byte", "bytes"])
        reg(.kilobytes, ["kb", "kilobyte", "kilobytes"])
        reg(.megabytes, ["mb", "megabyte", "megabytes"])
        reg(.gigabytes, ["gb", "gigabyte", "gigabytes"])
        reg(.terabytes, ["tb", "terabyte", "terabytes"])
        reg(.petabytes, ["pb", "petabyte", "petabytes"])
        reg(.exabytes, ["eb", "exabyte", "exabytes"])
        reg(.zettabytes, ["zb", "zettabyte", "zettabytes"])
        reg(.yottabytes, ["yb", "yottabyte", "yottabytes"])

        reg(.bits, ["bit", "bits"])
        reg(.kilobits, ["kbit", "kilobit", "kilobits"])
        reg(.megabits, ["mbit", "megabit", "megabits"])
        reg(.gigabits, ["gbit", "gigabit", "gigabits"])
        reg(.terabits, ["tbit", "terabit", "terabits"])
        reg(.petabits, ["pbit", "petabit", "petabits"])
        reg(.exabits, ["ebit", "exabit", "exabits"])
        reg(.zettabits, ["zbit", "zettabit", "zettabits"])
        reg(.yottabits, ["ybit", "yottabit", "yottabits"])

        reg(.kibibytes, ["kib", "kibibyte", "kibibytes"])
        reg(.mebibytes, ["mib", "mebibyte", "mebibytes"])
        reg(.gibibytes, ["gib", "gibibyte", "gibibytes"])
        reg(.tebibytes, ["tib", "tebibyte", "tebibytes"])
        reg(.pebibytes, ["pib", "pebibyte", "pebibytes"])
        reg(.exbibytes, ["eib", "exbibyte", "exbibytes"])
        reg(.zebibytes, ["zib", "zebibyte", "zebibytes"])
        reg(.yobibytes, ["yib", "yobibyte", "yobibytes"])

        reg(.kibibits, ["kibit", "kibibit", "kibibits"])
        reg(.mebibits, ["mibit", "mebibit", "mebibits"])
        reg(.gibibits, ["gibit", "gibibit", "gibibits"])
        reg(.tebibits, ["tibit", "tebibit", "tebibits"])
        reg(.pebibits, ["pibit", "pebibit", "pebibits"])
        reg(.exbibits, ["eibit", "exbibit", "exbibits"])
        reg(.zebibits, ["zibit", "zebibit", "zebibits"])
        reg(.yobibits, ["yibit", "yobibit", "yobibits"])
        return m
    }()
}
