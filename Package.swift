// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "URLLintPlugin",
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "URLLintPlugin",
            targets: ["URLLintPlugin"]),
    ],
    dependencies: [
        .package(url: "https://github.com/jpsim/SourceKitten.git", from: "0.32.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "URLLintPlugin",
            dependencies: []),
        .testTarget(
            name: "URLLintPluginTests",
            dependencies: ["URLLintPlugin"]),
        .executableTarget(
            name: "SafeURLLint",
            dependencies: [
                .product(name: "SourceKittenFramework", package: "SourceKitten"),
            ]
        ),
    ]
)
