// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ZenRetail",
    products: [
        .executable(
            name: "ZenRetail",
            targets: ["ZenRetail"]),
    ],
    dependencies: [
        .package(url: "https://github.com/gerardogrisolini/ZenNIO.git", .branch("swift-5.0")),
        .package(url: "https://github.com/gerardogrisolini/ZenPostgres.git", .branch("master")),
        .package(url: "https://github.com/gerardogrisolini/ZenSMTP.git", .branch("master")),
        .package(url: "https://github.com/gerardogrisolini/ZenMWS.git", .branch("master")),
        .package(url: "https://github.com/gerardogrisolini/ZenEBAY.git", .branch("master")),
        .package(url: "https://github.com/twostraws/SwiftGD.git", .branch("master")),
    ],
    targets: [
        .target(
            name: "ZenRetail",
            dependencies: ["ZenNIO", "ZenPostgres", "ZenSMTP", "ZenMWS", "ZenEBAY", "SwiftGD"]),
        .testTarget(
            name: "ZenRetailTests",
            dependencies: ["ZenRetail"]),
    ]
)
