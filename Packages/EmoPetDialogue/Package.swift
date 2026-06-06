// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "EmoPetDialogue",
    platforms: [.iOS(.v16), .macOS(.v14)],
    products: [
        .library(name: "EmoPetDialogue", targets: ["EmoPetDialogue"]),
    ],
    dependencies: [
        .package(path: "../EmoPetKit"),
        .package(path: "../EmoPetCore"),
    ],
    targets: [
        .target(
            name: "EmoPetDialogue",
            dependencies: ["EmoPetKit", "EmoPetCore"]
        ),
    ]
)
