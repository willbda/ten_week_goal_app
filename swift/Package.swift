// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TenWeekGoalApp",
    platforms: [
        .macOS(.v14)  // macOS-native for rapid development
    ],
    products: [
        .library(
            name: "TenWeekGoalApp",
            targets: ["Models"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/groue/GRDB.swift.git", from: "7.8.0")
    ],
    targets: [
        // Domain layer (pure, no infrastructure dependencies)
        .target(
            name: "Models",
            dependencies: [],
            path: "Sources/Models"
        ),
        // Infrastructure layer (Database operations)
        .target(
            name: "Database",
            dependencies: [
                "Models",
                .product(name: "GRDB", package: "GRDB.swift")
            ],
            path: "Sources/Database"
        ),
        // Translation layer (Storage services)
        .target(
            name: "Services",
            dependencies: [
                "Models",
                "Database",
                .product(name: "GRDB", package: "GRDB.swift")
            ],
            path: "Sources/Services"
        ),
        // Tests
        .testTarget(
            name: "TenWeekGoalAppTests",
            dependencies: ["Models", "Database", "Services"],
            path: "Tests"
        ),
    ]
)
