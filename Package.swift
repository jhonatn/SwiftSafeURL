// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "SafeURL",
    platforms: [
        .iOS("11.0"),
        .macOS("12")
    ],
    products: [
        .library(
            name: "SafeURL",
            targets: [
                "SafeURL",
            ]),
        .plugin(
            name: "SafeURLPlugin",
            targets: [
                "SafeURLPlugin",
            ])
    ],
    dependencies: [
        .package(url: "https://github.com/jpsim/SourceKitten.git", from: "0.32.0"),
        .package(url: "https://github.com/baguio/XcodeIssueReporting", .upToNextMajor(from: "1.0.0")),
    ],
    targets: [
        // Interface
        .target(
            name: "SafeURL"
        ),
        .plugin(
            name: "SafeURLPlugin",
            capability: .buildTool(),
            dependencies: ["SafeURLLintExecutable", "SafeURLLintFramework"]
        ),
        // Plugin internal code
        .target(
            name: "SafeURLLintFramework",
            dependencies: [
                .product(name: "SourceKittenFramework", package: "SourceKitten"),
                .product(name: "XcodeIssueReporting", package: "XcodeIssueReporting"),
                .product(name: "XcodeIssueReportingForSourceKitten", package: "XcodeIssueReporting"),
            ]
        ),
        .executableTarget(
            name: "SafeURLLintExecutable",
            dependencies: ["SafeURLLintFramework"]
        ),
        .executableTarget(
            name: "SafeURLPlayground",
            dependencies: ["SafeURL"],
            plugins: ["SafeURLPlugin"]
        ),
    ]
)
