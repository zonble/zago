import Foundation

/// Defines physical dimension categories for LogoMeasurementConverter.
public enum LogoDimensionKind: String, CaseIterable, Sendable {
    case area
    case length
    case volume
    case angle
    case mass
    case pressure
    case acceleration
    case duration
    case frequency
    case speed
    case energy
    case power
    case temperature
    case illuminance
    case electricCharge
    case electricCurrent
    case electricPotentialDifference
    case electricResistance
    case concentrationMass
    case dispersion
    case fuelEfficiency
    case informationStorage

    public var displayName: String {
        switch self {
        case .area: "Area"
        case .length: "Length"
        case .volume: "Volume"
        case .angle: "Angle"
        case .mass: "Mass"
        case .pressure: "Pressure"
        case .acceleration: "Acceleration"
        case .duration: "Duration"
        case .frequency: "Frequency"
        case .speed: "Speed"
        case .energy: "Energy"
        case .power: "Power"
        case .temperature: "Temperature"
        case .illuminance: "Illuminance"
        case .electricCharge: "Electric Charge"
        case .electricCurrent: "Electric Current"
        case .electricPotentialDifference: "Voltage"
        case .electricResistance: "Resistance"
        case .concentrationMass: "Concentration Mass"
        case .dispersion: "Dispersion"
        case .fuelEfficiency: "Fuel Efficiency"
        case .informationStorage: "Information Storage"
        }
    }

    public var supportedUnits: [String] {
        switch self {
        case .area:
            [
                "sqm", "m2", "sqkm", "km2", "sqcm", "cm2", "sqmm", "mm2", "squm", "sqnm", "sqin", "in2", "sqft", "ft2",
                "sqyd", "yd2", "sqmi", "mi2", "acre", "are", "ha",
            ]
        case .length:
            [
                "m", "km", "cm", "mm", "um", "nm", "pm", "dm", "dam", "hm", "in", "ft", "yd", "mi", "nmi", "furlong",
                "fathom", "ly", "pc", "au",
            ]
        case .volume:
            [
                "l", "ml", "cl", "dl", "kl", "m3", "km3", "cm3", "mm3", "in3", "ft3", "yd3", "mi3", "acrefeet",
                "bushel", "tsp", "tbsp", "floz", "cup", "pt", "qt", "gal",
            ]
        case .angle:
            ["deg", "rad", "grad", "rev", "arcmin", "arcsec"]
        case .mass:
            ["kg", "g", "mg", "ug", "ng", "pg", "t", "lb", "oz", "ozt", "ct", "st", "slug"]
        case .pressure:
            ["pa", "hpa", "kpa", "mpa", "gpa", "bar", "mbar", "atm", "mmhg", "torr", "inhg", "psi"]
        case .acceleration:
            ["m/s2", "gforce", "gee", "gravity"]
        case .duration:
            ["s", "sec", "min", "hr", "h", "day", "d", "ms", "us", "ns", "ps"]
        case .frequency:
            ["hz", "khz", "mhz", "ghz", "thz", "fps", "rpm"]
        case .speed:
            ["m/s", "km/h", "kmh", "mph", "knot", "kn"]
        case .energy:
            ["j", "kj", "mj", "gj", "cal", "kcal", "wh", "kwh", "mwh", "btu", "ev"]
        case .power:
            ["w", "kw", "mw", "gw", "hp", "ps"]
        case .temperature:
            ["c", "celsius", "f", "fahrenheit", "k", "kelvin"]
        case .illuminance:
            ["lx", "lux"]
        case .electricCharge:
            ["c", "coulomb", "ah", "mah", "uah"]
        case .electricCurrent:
            ["a", "amp", "ma", "ua", "ka"]
        case .electricPotentialDifference:
            ["v", "mv", "kv", "uv", "megavolt"]
        case .electricResistance:
            ["ohm", "kohm", "mohm", "microohm"]
        case .concentrationMass:
            ["g/l", "mg/dl", "mmol/l"]
        case .dispersion:
            ["ppm"]
        case .fuelEfficiency:
            ["l/100km", "mpg", "imperialmpg"]
        case .informationStorage:
            ["b", "byte", "kb", "mb", "gb", "tb", "pb", "bit", "kbit", "mbit", "gbit", "kib", "mib", "gib", "tib"]
        }
    }

    public static let supportedUnitsNote: String = {
        var lines = ["Supported measurement dimensions and units:"]
        for kind in allCases {
            lines.append("• \(kind.displayName): \(kind.supportedUnits.joined(separator: ", "))")
        }
        return lines.joined(separator: "\n")
    }()

    public init?(unit: String) {
        guard let kind = LogoMeasurementConverter.findDimension(for: unit) else { return nil }
        self = kind
    }

    public static func parse(unit: String) -> LogoDimensionKind? {
        LogoDimensionKind(unit: unit)
    }
}
