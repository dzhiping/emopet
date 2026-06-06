// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PetDog",
    platforms: [.iOS(.v16), .macOS(.v14)],
    products: [
        .library(name: "PetDog", targets: ["PetDog"]),
    ],
    dependencies: [
        .package(path: "../EmoPetKit"),
    ],
    targets: [
        .target(
            name: "PetDog",
            dependencies: ["EmoPetKit"],
            resources: [.process("Resources")]
        ),
    ]
)
