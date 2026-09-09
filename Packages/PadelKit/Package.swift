// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "PadelKit",
    platforms: [
        .iOS(.v17),
        .watchOS(.v10),
        .macOS(.v14),
    ],
    products: [
        .library(name: "PadelCore", targets: ["PadelCore"]),
        .library(name: "PadelUI", targets: ["PadelUI"]),
    ],
    targets: [
        .target(
            name: "PadelCore"
        ),
        .testTarget(
            name: "PadelCoreTests",
            dependencies: ["PadelCore"]
        ),
        .target(
            name: "PadelUI",
            dependencies: ["PadelCore"]
        ),
        .testTarget(
            name: "PadelUITests",
            dependencies: ["PadelUI"]
        ),
    ]
)
