// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "InsetTest",
    platforms: [.macOS(.v12)],
    dependencies: [
        .package(path: ".."),
    ],
    targets: [
        .executableTarget(
            name: "InsetTest",
            dependencies: [
                .product(name: "STTextView", package: "STTextView"),
            ],
            path: "."
        ),
    ]
)
