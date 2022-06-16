// swift-tools-version: 5.6

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
            name: "SafeURLPLugin",
            targets: [
                "SafeURLPlugin",
            ])
    ],
    dependencies: [
        .package(url: "https://github.com/jpsim/SourceKitten.git", from: "0.32.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "SafeURL",
            dependencies: [
            ]
        ),
        .executableTarget(
            name: "SafeURLLint",
            dependencies: [
                .product(name: "SourceKittenFramework", package: "SourceKitten"),
            ]
        ),
        .plugin(
            name: "SafeURLPlugin",
            capability: .buildTool(),
            dependencies: [
                "SafeURLLint"
            ]
        ),
        .executableTarget(
            name: "SafeURLPlayground",
            dependencies: [
                "SafeURL"
            ],
            plugins: [
                "SafeURLPlugin"
            ]
        ),
    ]
)
