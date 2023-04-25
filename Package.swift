// swift-tools-version:5.7

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
            name: "STTextView"
        ),
        .testTarget(
            name: "STTextViewTests",
            dependencies: ["STTextView"]
        )
    ]
)
