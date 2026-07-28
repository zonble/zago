// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "se",
    products: [
        .executable(name: "se", targets: ["se"]),
        .library(name: "LogoEngine", targets: ["LogoEngine"]),
        .library(name: "Editor", targets: ["Editor"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.3.0"),
    ],
    targets: [
        .target(
            name: "LogoEngine"
        ),
        .target(
            name: "Editor",
            dependencies: ["LogoEngine"]
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
            dependencies: ["Editor", "LogoEngine"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
