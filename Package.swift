// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "zago",
    products: [
        .executable(name: "zago", targets: ["zago"]),
        .library(name: "TextMetrics", targets: ["TextMetrics"]),
        .library(name: "Drawing", targets: ["Drawing"]),
        .library(name: "DocumentOutline", targets: ["DocumentOutline"]),
        .library(name: "LogoEngine", targets: ["LogoEngine"]),
        .library(name: "TextTransform", targets: ["TextTransform"]),
        .library(name: "Config", targets: ["Config"]),
        .library(name: "Syntax", targets: ["Syntax"]),
        .library(name: "Diagram", targets: ["Diagram"]),
        .library(name: "TextEncoding", targets: ["TextEncoding"]),
        .library(name: "SpellChecker", targets: ["SpellChecker"]),
        .library(name: "Git", targets: ["Git"]),
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
            name: "Drawing",
            dependencies: ["TextMetrics"]
        ),
        .target(
            name: "DocumentOutline"
        ),
        .target(
            name: "TextEncoding"
        ),
        .target(
            name: "Git"
        ),
        .target(
            name: "SpellChecker",
            linkerSettings: [
                .linkedFramework("AppKit", .when(platforms: [.macOS])),
                .linkedLibrary("ole32", .when(platforms: [.windows])),
            ]
        ),
        .target(
            name: "LogoEngine",
            dependencies: ["Drawing", "TextMetrics", "TextTransform"]
        ),
        .target(
            name: "TextTransform"
        ),
        .target(
            name: "Config",
            dependencies: ["Drawing"]
        ),
        .target(
            name: "Syntax",
            dependencies: ["DocumentOutline", "LogoEngine"]
        ),
        .target(
            name: "Diagram"
        ),
        .target(
            name: "Editor",
            dependencies: ["Config", "Diagram", "DocumentOutline", "Drawing", "Git", "LogoEngine", "SpellChecker", "Syntax", "TextEncoding", "TextMetrics", "TextTransform"]
        ),
        .executableTarget(
            name: "zago",
            dependencies: [
                "Config",
                "DocumentOutline",
                "Drawing",
                "Editor",
                "Git",
                "LogoEngine",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
        .testTarget(
            name: "zagoTests",
            dependencies: ["Config", "Diagram", "DocumentOutline", "Drawing", "Editor", "Git", "LogoEngine", "SpellChecker", "Syntax", "TextEncoding", "TextMetrics", "TextTransform"],
            path: "Tests"
        ),
    ],
    swiftLanguageModes: [.v6]
)
