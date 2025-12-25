// swift-tools-version:5.9

import PackageDescription

let package = Package(
    name: "STTextView",
    platforms: [.macOS(.v14), .iOS(.v16), .macCatalyst(.v16)],
    products: [
        .library(
            name: "STTextView",
            targets: ["STTextView", "STTextViewSwiftUI"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/krzyzanowskim/STTextKitPlus", from: "0.2.0"),
        .package(url: "https://github.com/krzyzanowskim/CoreTextSwift", from: "0.2.0")
    ],
    targets: [
        .target(
            name: "STTextView",
            dependencies: [
                .target(name: "STTextViewAppKit", condition: .when(platforms: [.macOS])),
                .target(name: "STTextViewUIKit", condition: .when(platforms: [.iOS, .macCatalyst]))
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
                .product(name: "STTextKitPlus", package: "STTextKitPlus"),
                .product(name: "CoreTextSwift", package: "CoreTextSwift")
            ]
        ),
        .target(
            name: "STTextViewUIKit",
            dependencies: [
                .target(name: "STTextViewCommon"),
                .target(name: "STObjCLandShim", condition: .when(platforms: [.iOS, .macCatalyst])),
                .product(name: "STTextKitPlus", package: "STTextKitPlus"),
                .product(name: "CoreTextSwift", package: "CoreTextSwift")
            ],
            swiftSettings: [
                // .define("USE_LAYERS_FOR_GLYPHS")
            ]
        ),
        .target(
            name: "STTextViewSwiftUI",
            dependencies: [
                .target(name: "STTextViewSwiftUIAppKit", condition: .when(platforms: [.macOS])),
                .target(name: "STTextViewSwiftUIUIKit", condition: .when(platforms: [.iOS, .macCatalyst]))
            ]
        ),
        .target(
            name: "STTextViewSwiftUICommon"
        ),
        .target(
            name: "STTextViewSwiftUIAppKit",
            dependencies: [
                .target(name: "STTextView"),
                .target(name: "STTextViewSwiftUICommon")
            ]
        ),
        .target(
            name: "STTextViewSwiftUIUIKit",
            dependencies: [
                .target(name: "STTextView"),
                .target(name: "STTextViewSwiftUICommon")
            ]
        ),
        .target(
            name: "STObjCLandShim",
            publicHeadersPath: "include"
        ),
        .testTarget(
            name: "STTextViewAppKitTests",
            dependencies: [
                .target(name: "STTextViewAppKit", condition: .when(platforms: [.macOS]))
            ]
        ),
        .testTarget(
            name: "STTextViewUIKitTests",
            dependencies: [
                .target(name: "STTextViewUIKit", condition: .when(platforms: [.iOS, .macCatalyst]))
            ]
        )
    ]
)
