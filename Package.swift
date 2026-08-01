// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "zago",
    products: [
        .executable(name: "zago", targets: ["zago"]),
        .library(name: "TextMetrics", targets: ["TextMetrics"]),
        .library(name: "LogoEngine", targets: ["LogoEngine"]),
        .library(name: "TextTransform", targets: ["TextTransform"]),
        .library(name: "Syntax", targets: ["Syntax"]),
        .library(name: "Diagram", targets: ["Diagram"]),
        .library(name: "Editor", targets: ["Editor"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.3.0"),
    ],
    targets: [
        .target(
            name: "TextMetrics"
        ),
        .target(
            name: "LogoEngine",
            dependencies: ["TextMetrics", "TextTransform"]
        ),
        .target(
            name: "TextTransform"
        ),
        .target(
            name: "Syntax",
            dependencies: ["LogoEngine"]
        ),
        .target(
            name: "Diagram"
        ),
        .target(
            name: "Editor",
            dependencies: ["Diagram", "LogoEngine", "Syntax", "TextMetrics"]
        ),
        .executableTarget(
            name: "zago",
            dependencies: [
                "Editor",
                "LogoEngine",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
        .testTarget(
            name: "zagoTests",
            dependencies: ["Diagram", "Editor", "LogoEngine", "Syntax", "TextMetrics", "TextTransform"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
