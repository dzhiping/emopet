// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "EmoPetPersistence",
    platforms: [.iOS(.v16), .macOS(.v14)],
    products: [
        .library(name: "EmoPetPersistence", targets: ["EmoPetPersistence"]),
    ],
    dependencies: [
        .package(path: "../EmoPetKit"),
        .package(path: "../EmoPetCore"),
        .package(path: "../EmoPetPersonality"),
    ],
    targets: [
        .target(
            name: "EmoPetPersistence",
            dependencies: ["EmoPetKit", "EmoPetCore", "EmoPetPersonality"]
        ),
    ]
)
