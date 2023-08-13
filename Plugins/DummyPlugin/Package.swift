// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "DummyPlugin",
    platforms: [.macOS(.v12)],
    products: [
        .library(
            name: "DummyPlugin",
            targets: ["DummyPlugin"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/krzyzanowskim/STTextView", from: "0.8.9")
    ],
    targets: [
        .target(
            name: "DummyPlugin",
            dependencies: [
                "STTextView"
            ]
        )
    ]
)
