// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "NSClear",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "nsclear",
            targets: ["NSClear"]
        )
    ],
    dependencies: [
        // SwiftSyntax for parsing and rewriting Swift code
        .package(url: "https://github.com/apple/swift-syntax.git", from: "510.0.0"),
        // IndexStoreDB for symbol indexing and reference resolution
        .package(url: "https://github.com/apple/indexstore-db.git", branch: "main"),
        // Swift Argument Parser for CLI
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.3.0"),
        // Yams for YAML configuration parsing
        .package(url: "https://github.com/jpsim/Yams.git", from: "5.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "NSClear",
            dependencies: [
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftParser", package: "swift-syntax"),
                .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
                .product(name: "IndexStoreDB", package: "indexstore-db"),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Yams", package: "Yams"),
            ],
            path: "Sources",
            swiftSettings: [
                .unsafeFlags(["-parse-as-library"])
            ]
        ),
        .testTarget(
            name: "NSClearTests",
            dependencies: ["NSClear"],
            path: "Tests"
        )
    ]
)
