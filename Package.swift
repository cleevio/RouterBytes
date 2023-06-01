// swift-tools-version: 5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let swiftSettings: [SwiftSetting] = [
// Only for development checks
//    SwiftSetting.unsafeFlags([
//        "-Xfrontend", "-strict-concurrency=complete",
//        "-Xfrontend", "-warn-concurrency",
//        "-Xfrontend", "-enable-actor-data-race-checks",
//    ])
]

let package = Package(
    name: "CleevioAPILibrary",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "CleevioAPI",
            targets: ["CleevioAPI"]),
        .library(
            name: "CleevioAuthentication",
            targets: ["CleevioAuthentication"]
        )
    ],
    dependencies: [
        .package(url: "git@gitlab.cleevio.cz:cleevio-dev-ios/CleevioCore", .upToNextMajor(from: .init(2, 0, 0))),
        .package(url: "git@gitlab.cleevio.cz:cleevio-dev-ios/CleevioStorage", .upToNextMajor(from: .init(0, 1, 3)))
    ],
    targets: [
        .target(
            name: "CleevioAPI",
            dependencies: [
                .product(name: "CleevioCore", package: "CleevioCore")
            ],
            swiftSettings: swiftSettings
        ),
        .target(
            name: "CleevioAuthentication",
            dependencies: [
                "CleevioAPI",
                "CleevioStorage"
            ],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "CleevioAPITests",
            dependencies: [
                "CleevioAPI",
                "CleevioAuthentication"
            ])
    ]
)
