// swift-tools-version: 6.3
import PackageDescription

let package = Package(
    name: "se",
    products: [
        .executable(name: "se", targets: ["se"]),
        .library(name: "Editor", targets: ["Editor"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.3.0"),
    ],
    targets: [
        .target(
            name: "Editor"
        ),
        .executableTarget(
            name: "se",
            dependencies: [
                "Editor",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
        .testTarget(
            name: "seTests",
            dependencies: ["Editor"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
