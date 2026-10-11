// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PhonePing",
    platforms: [.macOS(.v14)],
    products: [.executable(name: "PhonePing", targets: ["PhonePing"])],
    targets: [
        .target(name: "PhonePingCore"),
        .executableTarget(name: "PhonePing", dependencies: ["PhonePingCore"]),
        .testTarget(name: "PhonePingCoreTests", dependencies: ["PhonePingCore"])
    ]
)
