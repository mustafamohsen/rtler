// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "RtlerFloating",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "RtlerFloating", targets: ["RtlerFloating"]),
        .library(name: "RtlerFloatingCore", targets: ["RtlerFloatingCore"]),
    ],
    targets: [
        .target(
            name: "RtlerFloatingCore",
            linkerSettings: [
                .unsafeFlags(["-L", "../../target/release", "-L", "../../target/debug", "-lrtler"]),
            ]
        ),
        .executableTarget(name: "RtlerFloating", dependencies: ["RtlerFloatingCore"]),
        .testTarget(name: "RtlerFloatingTests", dependencies: ["RtlerFloatingCore"]),
    ]
)
