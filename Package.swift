// swift-tools-version: 5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CleevioAPILibrary",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "CleevioAPI",
            targets: ["CleevioAPI"]),
    ],
    dependencies: [
        .package(url: "git@gitlab.cleevio.cz:cleevio-dev-ios/CleevioCore", .upToNextMajor(from: .init(2, 0, 0))),
    ],
    targets: [
        .target(
            name: "CleevioAPI",
            dependencies: [
                .product(name: "CleevioCore", package: "CleevioCore")
            ]),
        .testTarget(
            name: "CleevioAPITests",
            dependencies: ["CleevioAPI"]),
    ]
)
