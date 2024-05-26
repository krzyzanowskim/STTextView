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
                .target(name: "STTextViewMac", condition: .when(platforms: [.macOS])),
                .target(name: "STTextViewiOS", condition: .when(platforms: [.iOS]))
            ]
        ),
        .target(
            name: "STTextViewCommon",
            dependencies: [
                .product(name: "STTextKitPlus", package: "STTextKitPlus")
            ]
        ),
        .target(
            name: "STTextViewMac",
            dependencies: [
                .target(name: "STTextViewCommon"),
                .target(name: "STObjCLandShim", condition: .when(platforms: [.macOS])),
                .product(name: "STTextKitPlus", package: "STTextKitPlus")
            ]
        ),
        .target(
            name: "STTextViewiOS",
            dependencies: [
                .target(name: "STTextViewCommon"),
                .target(name: "STObjCLandShim", condition: .when(platforms: [.iOS])),
                .product(name: "STTextKitPlus", package: "STTextKitPlus")
            ]
        ),
        .target(
            name: "STTextViewUI",
            dependencies: [
                .target(name: "STTextViewUIMac", condition: .when(platforms: [.macOS]))
            ]
        ),
        .target(
            name: "STTextViewUIMac",
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
