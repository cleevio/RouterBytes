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
    name: "CleevioAPI",
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
        ),
        .library(
            name: "APIMultipart",
            targets: ["APIMultipart"]
        ),
        .library(
            name: "APIServiceMock",
            targets: ["APIServiceMock"]
        )
    ],
    dependencies: [
        .package(url: "git@gitlab.cleevio.cz:cleevio-dev-ios/CleevioCore", .upToNextMajor(from: .init(2, 0, 0))),
        .package(url: "git@gitlab.cleevio.cz:cleevio-dev-ios/CleevioStorage", .upToNextMajor(from: "0.3.0-dev3"))
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
        .target(
            name: "APIServiceMock",
            dependencies: [
                "CleevioAPI",
            ],
            swiftSettings: swiftSettings
        ),
        .target(
            name: "APIMultipart",
            dependencies: [
                "CleevioAPI"
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
