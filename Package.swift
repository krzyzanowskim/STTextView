// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "STTextView",
    platforms: [.macOS(.v12)],
    products: [
        .library(
            name: "STTextView",
            targets: ["STTextView"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "STTextView",
            dependencies: [])
    ]
)
