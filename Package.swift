// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "se",
    products: [
        .executable(name: "se", targets: ["se"]),
        .library(name: "TextMetrics", targets: ["TextMetrics"]),
        .library(name: "LogoEngine", targets: ["LogoEngine"]),
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
            dependencies: ["TextMetrics"]
        ),
        .target(
            name: "Editor",
            dependencies: ["LogoEngine", "TextMetrics"]
        ),
        .executableTarget(
            name: "se",
            dependencies: [
                "Editor",
                "LogoEngine",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
        .testTarget(
            name: "seTests",
            dependencies: ["Editor", "LogoEngine", "TextMetrics"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
