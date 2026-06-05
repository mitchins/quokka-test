// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "QuokkaTest",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "QuokkaTest",
            targets: ["QuokkaTest"]
        )
    ],
    targets: [
        .target(
            name: "QuokkaTest",
            path: "Sources/QuokkaTest",
            swiftSettings: [.unsafeFlags(["-warnings-as-errors"])]
        ),
        .testTarget(
            name: "QuokkaTestTests",
            dependencies: ["QuokkaTest"],
            path: "Tests/QuokkaTestTests",
            swiftSettings: [.unsafeFlags(["-warnings-as-errors"])]
        )
    ]
)
