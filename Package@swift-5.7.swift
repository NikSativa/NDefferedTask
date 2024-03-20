// swift-tools-version:5.7
// swiftformat:disable all
import PackageDescription

let package = Package(
    name: "NDefferedTask",
    platforms: [
        .iOS(.v13),
        .macOS(.v11),
        .macCatalyst(.v13),
        .tvOS(.v13),
        .watchOS(.v6)
    ],
    products: [
        .library(name: "NDefferedTask", targets: ["NDefferedTask"])
    ],
    dependencies: [
        .package(url: "https://github.com/NikSativa/NQueue.git", .upToNextMinor(from: "1.2.4")),
        .package(url: "https://github.com/NikSativa/NSpry.git", .upToNextMinor(from: "2.1.4"))
    ],
    targets: [
        .target(name: "NDefferedTask",
                dependencies: [
                    "NQueue"
                ],
                path: "Source",
                resources: [
                    .copy("../PrivacyInfo.xcprivacy")
                ]),
        .testTarget(name: "NDefferedTaskTests",
                    dependencies: [
                        "NDefferedTask",
                        "NQueue",
                        "NSpry"
                    ],
                    path: "Tests")
    ]
)
