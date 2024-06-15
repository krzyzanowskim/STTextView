// swift-tools-version:5.9

import PackageDescription

let package = Package(
    name: "STTextView",
    platforms: [.macOS(.v12), .iOS(.v16)],
    products: [
        .library(
            name: "STTextView",
            targets: ["STTextView", "STTextViewUI"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/krzyzanowskim/STTextKitPlus", from: "0.1.2")
    ],
    targets: [
        .target(
            name: "STTextView",
            dependencies: [
                .target(name: "STTextViewAppKit", condition: .when(platforms: [.macOS])),
                .target(name: "STTextViewUIKit", condition: .when(platforms: [.iOS]))
            ]
        ),
        .target(
            name: "STTextViewCommon",
            dependencies: [
                .product(name: "STTextKitPlus", package: "STTextKitPlus")
            ]
        ),
        .target(
            name: "STTextViewAppKit",
            dependencies: [
                .target(name: "STTextViewCommon"),
                .target(name: "STObjCLandShim", condition: .when(platforms: [.macOS])),
                .product(name: "STTextKitPlus", package: "STTextKitPlus")
            ]
        ),
        .target(
            name: "STTextViewUIKit",
            dependencies: [
                .target(name: "STTextViewCommon"),
                .target(name: "STObjCLandShim", condition: .when(platforms: [.iOS])),
                .product(name: "STTextKitPlus", package: "STTextKitPlus")
            ]
        ),
        .target(
            name: "STTextViewUI",
            dependencies: [
                .target(name: "STTextViewUIAppKit", condition: .when(platforms: [.macOS]))
            ]
        ),
        .target(
            name: "STTextViewUIAppKit",
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
