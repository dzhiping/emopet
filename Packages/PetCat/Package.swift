// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PetCat",
    platforms: [.iOS(.v16), .macOS(.v14)],
    products: [
        .library(name: "PetCat", targets: ["PetCat"]),
    ],
    dependencies: [
        .package(path: "../EmoPetKit"),
    ],
    targets: [
        .target(
            name: "PetCat",
            dependencies: ["EmoPetKit"],
            resources: [.process("Resources")]
        ),
    ]
)
