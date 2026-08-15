import Foundation
import Testing

@testable import LogoEngine

@Suite struct LogoPrimitiveMetaTests {
    @Test func testAllLogoPrimitivesHaveValidMetadata() {
        for prim in LogoPrimitive.allCases {
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

    @Test func testLogoPrimitiveExamplesStartWithKnownCommandAlias() {
        for prim in LogoPrimitive.allCases {
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
}
