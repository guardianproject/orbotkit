// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "OrbotKit",
    platforms: [
        .iOS(.v15),
    ],
    products: [
        .library(name: "OrbotKit", targets: ["OrbotKit"])
    ],
    targets: [
        .target(
            name: "OrbotKit",
            dependencies: []
        )
    ]
)