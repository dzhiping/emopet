// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "EmoPetKit",
    platforms: [.iOS(.v16), .macOS(.v14)],
    products: [
        .library(name: "EmoPetKit", targets: ["EmoPetKit"]),
    ],
    targets: [
        .target(name: "EmoPetKit"),
    ]
)
