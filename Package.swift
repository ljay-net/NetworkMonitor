// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "NetworkMonitor",
    platforms: [
        .macOS(.v13),
        .iOS(.v16)
    ],
    products: [
        .executable(name: "NetworkMonitor", targets: ["NetworkMonitor"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "NetworkMonitor",
            dependencies: [],
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "NetworkMonitorTests",
            dependencies: ["NetworkMonitor"]
        )
    ]
)