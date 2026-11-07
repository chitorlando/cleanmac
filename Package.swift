// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "CleanMac",
    platforms: [.macOS(.v15)],
    products: [
        .executable(name: "CleanMac", targets: ["CleanMacApp"])
    ],
    targets: [
        .target(name: "CleanMacCore"),
        .target(name: "CleanMacUI"),
        .target(
            name: "SystemJunkFeature",
            dependencies: ["CleanMacCore", "CleanMacUI"]
        ),
        .target(name: "LargeFilesFeature", dependencies: ["CleanMacCore"]),
        .executableTarget(
            name: "CleanMacApp",
            dependencies: ["CleanMacCore", "CleanMacUI", "SystemJunkFeature"]
        ),
        .testTarget(name: "CleanMacCoreTests", dependencies: ["CleanMacCore"]),
        .testTarget(
            name: "SystemJunkFeatureTests",
            dependencies: ["SystemJunkFeature", "CleanMacCore"]
        ),
        .testTarget(
            name: "LargeFilesFeatureTests",
            dependencies: ["LargeFilesFeature", "CleanMacCore"]
        )
    ]
)
