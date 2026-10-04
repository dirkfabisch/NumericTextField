// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "NumericTextField",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "NumericTextField",
            targets: ["NumericTextField"]
        ),
    ],
    targets: [
        .target(
            name: "NumericTextField"
        ),
        .testTarget(
            name: "NumericTextFieldTests",
            dependencies: ["NumericTextField"]
        ),
    ]
)
