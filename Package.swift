// swift-tools-version: 6.0
import Foundation
import PackageDescription

/// Info.plist embedded in the executable, so launches from Xcode or `swift run`
/// get the same identity and languages as the bundled app.
let infoPlistPath = URL(filePath: #filePath)
    .deletingLastPathComponent()
    .appending(path: "Support/Info.plist")
    .path

let package = Package(
    name: "CleanMac",
    defaultLocalization: "en",
    platforms: [.macOS(.v15)],
    products: [
        .executable(name: "CleanMac", targets: ["CleanMacApp"])
    ],
    targets: [
        .target(name: "CleanMacCore"),
        .target(name: "CleanMacUI", resources: [.process("Resources")]),
        .target(
            name: "SystemJunkFeature",
            dependencies: ["CleanMacCore", "CleanMacUI"]
        ),
        .executableTarget(
            name: "CleanMacApp",
            dependencies: ["CleanMacCore", "CleanMacUI", "SystemJunkFeature"],
            linkerSettings: [
                .unsafeFlags([
                    "-Xlinker", "-sectcreate",
                    "-Xlinker", "__TEXT",
                    "-Xlinker", "__info_plist",
                    "-Xlinker", infoPlistPath
                ])
            ]
        ),
        .testTarget(name: "CleanMacCoreTests", dependencies: ["CleanMacCore"]),
        .testTarget(
            name: "SystemJunkFeatureTests",
            dependencies: ["SystemJunkFeature", "CleanMacCore"]
        )
    ]
)
