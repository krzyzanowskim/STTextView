// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "NeonPlugin",
    platforms: [.macOS(.v12)],
    products: [
        .library(
            name: "NeonPlugin",
            targets: ["NeonPlugin"]),
    ],
    dependencies: [
        .package(url: "https://github.com/krzyzanowskim/STTextView", from: "0.8.9"),
        .package(url: "https://github.com/ChimeHQ/Neon.git", from: "0.5.1")
    ],
    targets: [
        .target(
            name: "NeonPlugin",
            dependencies: [
                "STTextView",
                "Neon"
            ]
        )
    ]
)
