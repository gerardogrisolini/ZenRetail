// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ZenRetail",
    platforms: [
        .macOS(.v10_15)
    ],
    products: [
        .library(name: "ZenRetailCore", targets: ["ZenRetailCore"]),
        .executable(name: "ZenRetail", targets: ["ZenRetail"]),
    ],
    dependencies: [
        .package(url: "https://github.com/gerardogrisolini/ZenNIO.git", .branch("master")),
        .package(url: "https://github.com/gerardogrisolini/ZenPostgres.git", .branch("master")),
        .package(url: "https://github.com/gerardogrisolini/ZenSMTP.git", .branch("master")),
//        .package(url: "https://github.com/gerardogrisolini/ZenMWS.git", .branch("master")),
//        .package(url: "https://github.com/gerardogrisolini/ZenEBAY.git", .branch("master")),
//        .package(url: "https://github.com/krzyzanowskim/CryptoSwift.git", from: "1.3.2"),
        .package(url: "https://github.com/tadija/AEXML.git", .branch("master")),
	.package(url: "https://github.com/koher/swift-image.git", from: "0.7.1")
    ],
    targets: [
        .target(
            name: "ZenRetailCore",
            dependencies: [
                "ZenNIO",
                "ZenNIOSSL",
                "ZenPostgres",
                "ZenSMTP",
//                "ZenMWS",
//                "ZenEBAY",
//                "CryptoSwift",
                "AEXML",
                "SwiftImage"
            ]
        ),
        .target(
            name: "ZenRetail",
            dependencies: ["ZenRetailCore"]),
        .testTarget(
            name: "ZenRetailTests",
            dependencies: ["ZenRetailCore"]),
    ],
    swiftLanguageVersions: [.v5]
)
