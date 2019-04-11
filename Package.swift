// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ZenRetail",
    products: [
        .library(
            name: "ZenRetailCore",
            targets: ["ZenRetailCore"]),
        .executable(
            name: "ZenRetail",
            targets: ["ZenRetail"]),
    ],
    dependencies: [
        .package(url: "https://github.com/gerardogrisolini/ZenNIO.git", .branch("master")),
        .package(url: "https://github.com/gerardogrisolini/ZenPostgres.git", .branch("master")),
        .package(url: "https://github.com/gerardogrisolini/ZenSMTP.git", .branch("master")),
        .package(url: "https://github.com/gerardogrisolini/ZenMWS.git", .branch("master")),
        .package(url: "https://github.com/gerardogrisolini/ZenEBAY.git", .branch("master")),
        .package(url: "https://github.com/twostraws/SwiftGD.git", from: "2.0.0"),
        .package(url: "https://github.com/krzyzanowskim/CryptoSwift.git", .branch("master")),
    ],
    targets: [
        .target(
            name: "ZenRetailCore",
            dependencies: ["ZenNIO", "ZenNIOSSL", "ZenNIOH2", "ZenPostgres", "ZenSMTP", "ZenMWS", "ZenEBAY", "SwiftGD", "CryptoSwift"]),
        .target(
            name: "ZenRetail",
            dependencies: ["ZenRetailCore"]),
        .testTarget(
            name: "ZenRetailTests",
            dependencies: ["ZenRetailCore"]),
    ]
)
