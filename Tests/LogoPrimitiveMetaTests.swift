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
        }
    }
}
