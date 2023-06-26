// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "OrbotKit",
    platforms: [
        .iOS(.v11),
    ],
    products: [
        .library(name: "OrbotKit", targets: ["OrbotKit"])
    ],
    targets: [
        .target(
            name: "OrbotKit"
        )
    ]
)
