import Foundation
import Testing

@testable import LogoEngine

@Suite struct LogoPrimitiveMetaTests {
    @Test func testAllLogoPrimitivesHaveValidMetadata() {
        for prim in availablePrimitives {
            let meta = prim.meta
            #expect(!meta.name.isEmpty, "Primitive \(prim) has empty name")
            #expect(!meta.description.isEmpty, "Primitive \(prim) has empty description")
            #expect(!meta.localizedDescriptionKey.isEmpty, "Primitive \(prim) has empty localizedDescriptionKey")
            #expect(
                LogoPrimitive.from(meta.name) == prim,
                "Primitive \(prim) has non-resolvable or mismatched metadata name \(meta.name)"
            )
        }
    }

    @Test func testAllPrimitiveParametersHaveDescriptionAndExample() {
        for primitive in LogoPrimitive.allCases {
            for parameter in primitive.meta.parameters ?? [] {
                #expect(
                    !(parameter.description?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true),
                    "\(primitive) parameter \(parameter.name) has no description"
                )
                #expect(
                    !(parameter.example?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true),
                    "\(primitive) parameter \(parameter.name) has no example"
                )
            }
        }
    }

    @Test func testLogoPrimitiveExamplesStartWithKnownCommandAlias() {
        for prim in availablePrimitives {
            let meta = prim.meta
            for example in meta.examples ?? [] {
                guard let firstToken = example.input.split(whereSeparator: \.isWhitespace).first else {
                    continue
                }

                let command = String(firstToken)
                #expect(
                    LogoPrimitive.from(command) != nil,
                    "Primitive \(prim) example starts with unknown command \(command): \(example.input)"
                )
            }
        }
    }

    @Test func testMetadataMatchesSupportedOptionalArguments() {
        let lineStyles = ["single", "heavy", "double", "round", "double-round", "ascii", "ascii-round", "triple-dash", "heavy-triple-dash", "quadruple-dash", "heavy-quadruple-dash", "double-dash", "heavy-double-dash"]
        #expect(LogoPrimitive.line.meta.parameters?[1].allowedValues == lineStyles)
        #expect(LogoPrimitive.vline.meta.parameters?[1].allowedValues == lineStyles)
        #expect(LogoPrimitive.justify.meta.parameters == nil)
        #expect(LogoPrimitive.formatRelativeTime.meta.parameters?[1].required == false)
        #expect(LogoPrimitive.formatRelativeTime.meta.notes == "Not supported on Linux or Windows.")
        #expect(LogoPrimitive.formatList.meta.notes == "Not supported on Linux or Windows.")
        #expect(LogoPrimitive.formatList.meta.parameters?[0].description == "The list or array to format.")
        #expect(LogoPrimitive.formatList.meta.parameters?[0].example == "[A B C]")
        #expect(LogoPrimitive.invoke.meta.parameters?.last?.name == "...")
        #expect(LogoPrimitive.sort.meta.parameters?.map(\.name) == ["list", "order", "template"])
    }

    @Test func testRelativeTimeAvailabilityMatchesPlatformSupport() {
        #expect(LogoPrimitive.from("FORMAT.RELATIVETIME") == .formatRelativeTime)
    }

#if os(Linux) || os(Windows)
    @Test func testListFormatterReportsUnsupportedPlatformError() {
        let engine = LogoEngine()
        var index = 0
        _ = engine.evaluateExpression(["FORMAT.LIST", "[", "A", "B", "]"], index: &index)
        #expect(engine.lastError?.message == "[LOGO Error: FORMAT.LIST is not supported on this platform]")
    }
#endif

#if os(Linux) || os(Windows)
    @Test func testRelativeTimeReportsUnsupportedPlatformError() {
        let engine = LogoEngine()
        var index = 0
        _ = engine.evaluateExpression(["FORMAT.RELATIVETIME", "-1", "\"day"], index: &index)
        #expect(engine.lastError?.message == "[LOGO Error: FORMAT.RELATIVETIME is not supported on this platform]")
    }
#endif

    private var availablePrimitives: [LogoPrimitive] {
        LogoPrimitive.allCases
    }
}
