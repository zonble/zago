import Foundation
import LogoEngine

public enum LogoWorkspaceContent {
    public static func lines(engine: LogoEngine, language: Language = .detectSystemLanguage()) -> [String] {
        var output = [
            "",
            L10n.string("logoworkspace.procedures", language: language),
        ]

        let procedures = engine.customProcedures.values.sorted { $0.name < $1.name }
        if procedures.isEmpty {
            output.append(L10n.string("logoworkspace.none", language: language))
        } else {
            for procedure in procedures {
                let params = procedure.parameters.map { ":\($0)" }.joined(separator: " ")
                output.append("    \(procedure.name.uppercased())\(params.isEmpty ? "" : " \(params)")")
                output.append("      \(procedure.bodyTokens.joined(separator: " "))")
            }
        }

        output += [
            "",
            L10n.string("logoworkspace.variables", language: language),
        ]

        let variables = engine.variables.sorted { $0.key < $1.key }
        if variables.isEmpty {
            output.append(L10n.string("logoworkspace.none", language: language))
        } else {
            for (name, value) in variables {
                output.append("    \(name) = \(value)")
            }
        }

        output += [
            "",
            L10n.string("logoworkspace.tip_1", language: language),
            L10n.string("logoworkspace.tip_2", language: language),
        ]

        return output
    }
}
