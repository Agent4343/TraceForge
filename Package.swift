// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "FormFlow",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "FormFlow",
            targets: ["FormFlow"]
        ),
    ],
    targets: [
        .target(
            name: "FormFlow",
            path: "FormFlow"
        ),
    ]
)
