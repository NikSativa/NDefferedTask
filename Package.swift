// swift-tools-version:5.8
// swiftformat:disable all
import PackageDescription

let package = Package(
    name: "NDefferedTask",
    platforms: [
        .iOS(.v13),
        .macOS(.v11)
    ],
    products: [
        .library(name: "NDefferedTask", targets: ["NDefferedTask"])
    ],
    dependencies: [
        .package(url: "https://github.com/NikSativa/NQueue.git", .upToNextMinor(from: "1.2.2")),
        .package(url: "https://github.com/NikSativa/NSpry.git", .upToNextMinor(from: "2.1.0"))
    ],
    targets: [
        .target(name: "NDefferedTask",
                dependencies: [
                    "NQueue"
                ],
                path: "Source"
               ),
        .testTarget(name: "NDefferedTaskTests",
                    dependencies: [
                        "NDefferedTask",
                        "NQueue",
                        "NSpry"
                    ],
                    path: "Tests"
                   )
    ]
)
