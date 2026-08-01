import Foundation

public struct PlantUMLSyntaxDefinition: SyntaxDefinition {
    public let name = "PlantUML"
    public let fileExtensions = ["puml", "plantuml", "iuml"]

    public var rules: [SyntaxRule] {
        [
            makeRule("'[^\\n]*$", .comment),
            makeRule("\"[^\"]*\"", .string),
            makeRule("@(start|end)[A-Za-z0-9_]*", .keyword),
            makeRule(
                "\\b(actor|agent|artifact|boundary|card|class|cloud|collections|component|control|database|entity|enum|file|folder|frame|interface|node|package|participant|queue|rectangle|stack|storage|usecase|abstract|annotation|circle|diamond|hide|show|skinparam|title|caption|legend|note|left|right|top|bottom|of|over|as|if|else|elseif|endif|while|endwhile|repeat|endrepeat|fork|endfork|group|end|alt|opt|loop|par|break|critical|newpage|autonumber|activate|deactivate|destroy|return)\\b",
                .keyword),
            makeRule("(?:<\\|--|--\\|>|\\*--|--\\*|o--|--o|<--|-->|<-|->|\\.\\.|--)", .typeOrAttribute),
            makeRule("\\b([0-9]+)\\b", .number),
        ].compactMap { $0 }
    }
}
