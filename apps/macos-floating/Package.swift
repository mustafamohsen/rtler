// swift-tools-version: 5.10
// Copyright (c) 2026 Mustafa Mohsen
// SPDX-License-Identifier: MIT
import PackageDescription

let package = Package(
    name: "RTLer",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "RTLer", targets: ["RTLer"]),
        .library(name: "RtlerFloatingCore", targets: ["RtlerFloatingCore"]),
    ],
    targets: [
        .target(
            name: "RtlerFloatingCore",
            linkerSettings: [
                .unsafeFlags(["-L", "../../target/release", "-L", "../../target/debug", "-lrtler"]),
            ]
        ),
        .executableTarget(name: "RTLer", dependencies: ["RtlerFloatingCore"]),
        .testTarget(name: "RtlerFloatingTests", dependencies: ["RtlerFloatingCore"]),
    ]
)
