// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "zago",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "zago", targets: ["zago"]),
        .executable(name: "zagoweb", targets: ["zagoweb"]),
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
        .library(name: "IPCServer", targets: ["IPCServer"]),
        .library(name: "ANSIStyle", targets: ["ANSIStyle"]),
        .library(name: "Editor", targets: ["Editor"]),
        .library(name: "FileWatcher", targets: ["FileWatcher"]),
        .library(name: "NumberHelpers", targets: ["NumberHelpers"]),
        .library(name: "LogoLocalization", targets: ["LogoLocalization"]),
        .library(name: "SystemClipboard", targets: ["SystemClipboard"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.3.0"),
        .package(url: "https://github.com/zonble/TmdSwift.git", from: "0.1.0"),
    ],
    targets: [
        .target(
            name: "NumberHelpers"
        ),
        .target(
            name: "FileWatcher"
        ),
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
            dependencies: ["Drawing", "NumberHelpers", "TextMetrics", "TextTransform"]
        ),
        .target(
            name: "LogoLocalization",
            dependencies: ["LogoEngine"]
        ),
        .target(
            name: "TextTransform"
        ),
        .target(
            name: "Config",
            dependencies: ["Drawing"]
        ),
        .target(
            name: "IPCServer",
            dependencies: ["Config", "Drawing", "LogoEngine", "TextMetrics"]
        ),
        .target(
            name: "ANSIStyle"
        ),
        .target(
            name: "Syntax",
            dependencies: ["ANSIStyle", "DocumentOutline", "LogoEngine", "LogoLocalization"]
        ),
        .target(
            name: "Diagram"
        ),
        .target(
            name: "Editor",
            dependencies: [
                "ANSIStyle", "Config", "Diagram", "DocumentOutline", "Drawing", "Git", "LogoEngine", "LogoLocalization", "SpellChecker",
                "Syntax", "TextEncoding", "TextMetrics", "TextTransform",
            ]
        ),
        .target(
            name: "ANSITerminal",
            dependencies: ["Config"]
        ),
        .target(
            name: "SystemClipboard",
            dependencies: ["Editor"],
            linkerSettings: [
                .linkedFramework("AppKit", .when(platforms: [.macOS])),
                .linkedLibrary("user32", .when(platforms: [.windows])),
            ]
        ),
        .executableTarget(
            name: "zago",
            dependencies: [
                "ANSITerminal",
                "Config",
                "DocumentOutline",
                "Drawing",
                "Editor",
                "FileWatcher",
                "Git",
                "IPCServer",
                "LogoEngine",
                "LogoLocalization",
                "SystemClipboard",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "TmdSwift", package: "TmdSwift"),
                .product(name: "TmdMIDI", package: "TmdSwift"),
                .product(name: "TmdMusicXML", package: "TmdSwift"),
                .product(name: "TmdLilyPond", package: "TmdSwift"),
                .product(name: "TmdABC", package: "TmdSwift"),
                .product(name: "TmdAudio", package: "TmdSwift", condition: .when(platforms: [.macOS])),
            ]
        ),
        .executableTarget(
            name: "zagoweb",
            dependencies: [
                "ANSITerminal",
                "Config",
                "Editor",
                "Git",
                "LogoEngine",
            ],
            path: "Sources/zagoweb"
        ),
        .testTarget(
            name: "zagoTests",
            dependencies: [
                "ANSITerminal", "Config", "Diagram", "DocumentOutline", "Drawing", "Editor", "FileWatcher", "Git", "IPCServer", "LogoEngine",
                "LogoLocalization", "NumberHelpers", "SpellChecker", "SystemClipboard",
                "Syntax", "TextEncoding", "TextMetrics", "TextTransform", "zago", "zagoweb",
            ],
            path: "Tests"
        ),
    ],
    swiftLanguageModes: [.v6]
)
