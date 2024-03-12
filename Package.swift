// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MQTTCLIPOC",
    platforms: [.macOS(.v12), .iOS(.v16), .tvOS(.v15), .watchOS(.v8)],
    dependencies: [
        .package(
                url: "https://github.com/swift-server-community/mqtt-nio",
                    .upToNextMinor(from: "2.11.0")
            )
        ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .executableTarget(
            name: "MQTTCLIPOC",
            dependencies: [.product(name: "MQTTNIO", package: "mqtt-nio")]
        )
    ]
)
