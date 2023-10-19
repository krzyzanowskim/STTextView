// swift-tools-version:5.7

import PackageDescription

let package = Package(
    name: "STTextView",
    platforms: [.macOS(.v12)],
    products: [
        .library(
            name: "STTextView",
            targets: ["STTextView", "STCompletion", "STTextViewUI"]
        ),
        .library(
            name: "STCompletion",
            targets: ["STCompletion"]
        ),
        .library(
            name: "STTextKitPlus",
            targets: ["STTextKitPlus"]
        ),
    ],
    targets: [
        .target(
            name: "STTextView",
            dependencies: [
                .target(name: "STTextKitPlus"),
                .target(name: "STCompletion")
            ]
        ),
        .target(
            name: "STTextKitPlus"
        ),
        .target(
        	name: "STCompletion"
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
        ),
        .testTarget(
            name: "STTextKitPlusTests",
            dependencies: [
                .target(name: "STTextKitPlus")
            ]
        )
    ]
)
