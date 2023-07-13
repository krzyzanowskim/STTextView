// swift-tools-version:5.7

import PackageDescription

let package = Package(
    name: "STTextView",
    platforms: [.macOS(.v12)],
    products: [
        .library(
            name: "STTextView",
            targets: ["STTextView", "STTextViewUI"]
        ),
        .library(
            name: "STTextKitPlus",
            targets: ["STTextKitPlus"]
        )
    ],
    targets: [
        .target(
            name: "STTextView",
            dependencies: [
                .target(name: "STTextKitPlus")
            ]
        ),
        .target(
            name: "STTextKitPlus"
        ),
        .target(
            name: "STTextViewUI",
            dependencies: [
                .target(name: "STTextView")
            ]
        ),
        .testTarget(
            name: "STTextViewTests",
            dependencies: [
                .target(name: "STTextView")
            ]
        )
    ]
)
