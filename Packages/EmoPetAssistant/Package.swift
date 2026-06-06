// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "EmoPetAssistant",
    platforms: [.iOS(.v16), .macOS(.v14)],
    products: [
        .library(name: "EmoPetAssistant", targets: ["EmoPetAssistant"]),
    ],
    dependencies: [
        .package(path: "../EmoPetKit"),
        .package(path: "../EmoPetCore"),
    ],
    targets: [
        .target(
            name: "EmoPetAssistant",
            dependencies: ["EmoPetKit", "EmoPetCore"]
        ),
    ]
)
