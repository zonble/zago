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

    public init?(unit: String) {
        guard let kind = LogoMeasurementConverter.findDimension(for: unit) else { return nil }
        self = kind
    }

    public static func parse(unit: String) -> LogoDimensionKind? {
        LogoDimensionKind(unit: unit)
    }
}
