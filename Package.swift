// swift-tools-version:5.7

import PackageDescription

let package = Package(
    name: "STTextView",
    platforms: [.macOS(.v12)],
    products: [
        .library(
            name: "STTextView",
            targets: ["STTextView", "STCompletion", "STTextViewUI"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/krzyzanowskim/STTextKitPlus", from: "0.0.2")
    ],
    targets: [
        .target(
            name: "STTextView",
            dependencies: [
                .target(name: "STCompletion"),
                .product(name: "STTextKitPlus", package: "STTextKitPlus"),
                "STObjCLandShim"
            ]
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
        .target(
            name: "STObjCLandShim",
            publicHeadersPath: "include"
        ),
        .testTarget(
            name: "STTextViewTests",
            dependencies: [
                .target(name: "STTextView")
            ]
        )
    ]
)
