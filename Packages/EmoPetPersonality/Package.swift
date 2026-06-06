// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "EmoPetPersonality",
    platforms: [.iOS(.v16), .macOS(.v14)],
    products: [
        .library(name: "EmoPetPersonality", targets: ["EmoPetPersonality"]),
    ],
    dependencies: [
        .package(path: "../EmoPetKit"),
    ],
    targets: [
        .target(
            name: "EmoPetPersonality",
            dependencies: ["EmoPetKit"]
        ),
    ]
)
