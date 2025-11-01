// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "GoalTracker",
    platforms: [
        .macOS(.v26),  // macOS 26+ for platform convergence
        .iOS(.v26)     // iOS 26+ for unified APIs (.sidebarAdaptable, .glassEffect)
    ],
    products: [
        // Shared library for iOS/macOS apps
        .library(
            name: "GoalTrackerKit",
            targets: ["Models", "BusinessLogic", "App"]
        ),
        // Command-line executable for testing
        .executable(
            name: "GoalTrackerCLI",
            targets: ["AppRunner"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/sqlite-data.git", from: "1.2.0")
    ],
    targets: [
        // Domain layer (with GRDB for direct conformance)
        .target(
            name: "Models",
            dependencies: [
                .product(name: "SQLiteData", package: "sqlite-data")
            ],
            path: "Sources/Models"
        ),
        // Business logic layer (matching, inference, progress calculations)
        .target(
            name: "BusinessLogic",
            dependencies: ["Models"],
            path: "Sources/BusinessLogic",
            exclude: [
                "LLM/ConversationService.swift.disabled",
                "LLM/Tools/GetActionsTool.swift.disabled",
                "LLM/Tools/GetGoalsTool.swift.disabled",
                "LLM/Tools/GetValuesTool.swift.disabled",
                "LLM/Tools/GetTermsTool.swift.disabled"
            ]
        ),
        // SwiftUI App Views (iOS/macOS library)
        .target(
            name: "App",
            dependencies: [
                "Models",
                "BusinessLogic",
                .product(name: "SQLiteData", package: "sqlite-data")
            ],
            path: "Sources/App",
            exclude: [
                "AppViewModel.swift.disabled",
                "GoalDocument.swift.disabled",
                "Views/Assistant/AssistantChatView.swift.disabled",
                "Views/Assistant/ChatMessage.swift.disabled",
                "Views/Assistant/ChatMessageRow.swift.disabled",
                "Views/Assistant/ConversationViewModel.swift.disabled"
            ]
        ),
        // Command-line executable target
        .executableTarget(
            name: "AppRunner",
            dependencies: [
                "Models",
                "App",
                .product(name: "SQLiteData", package: "sqlite-data")
            ],
            path: "Sources/AppRunner",
            exclude: ["Info.plist"]
        ),
        // Tests
        .testTarget(
            name: "GoalTrackerTests",
            dependencies: ["Models", "BusinessLogic", "App"],
            path: "Tests",
            exclude: [
                "ViewTests/README.md"
            ]
        ),
    ]
)
