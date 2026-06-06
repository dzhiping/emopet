// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "EmoPetCore",
    platforms: [.iOS(.v16), .macOS(.v14)],
    products: [
        .library(name: "EmoPetCore", targets: ["EmoPetCore"]),
    ],
    dependencies: [
        .package(path: "../EmoPetKit"),
    ],
    targets: [
        .target(
            name: "EmoPetCore",
            dependencies: ["EmoPetKit"]
        ),
        .testTarget(
            name: "EmoPetCoreTests",
            dependencies: ["EmoPetCore"]
        ),
    ]
)
