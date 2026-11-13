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
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "CleanMac", targets: ["CleanMacApp"])
    ],
    targets: [
        // Same binary target and checksum as Sparkle's official 2.10.1 manifest.
        // Fetch the release directly instead of cloning its entire Git history.
        .binaryTarget(
            name: "Sparkle",
            url: "https://github.com/sparkle-project/Sparkle/releases/download/2.10.1/Sparkle-for-Swift-Package-Manager.zip",
            checksum: "4c2e48a3e50ebcc2c88a58a4c7264a1a99c3c31857ce754357afb9cdb323022a"
        ),
        .target(name: "CleanMacCore"),
        .target(
            name: "CleanMacUI",
            dependencies: ["CleanMacCore"],
            resources: [.process("Resources")]
        ),
        .target(
            name: "SystemJunkFeature",
            dependencies: ["CleanMacCore", "CleanMacUI"],
            resources: [.process("Resources")]
        ),
        .target(
            name: "LargeFilesFeature",
            dependencies: ["CleanMacCore", "CleanMacUI"],
            resources: [.process("Resources")]
        ),
        .target(
            name: "MaintenanceFeature",
            dependencies: ["CleanMacCore", "CleanMacUI"],
            resources: [.process("Resources")]
        ),
        .target(
            name: "UninstallerFeature",
            dependencies: ["CleanMacCore", "CleanMacUI"],
            resources: [.process("Resources")]
        ),
        .target(
            name: "DuplicatesFeature",
            dependencies: ["CleanMacCore", "CleanMacUI"],
            resources: [.process("Resources")]
        ),
        .target(
            name: "DiskMapFeature",
            dependencies: ["CleanMacCore", "CleanMacUI"],
            resources: [.process("Resources")]
        ),
        .target(
            name: "PrivacyFeature",
            dependencies: ["CleanMacCore", "CleanMacUI"],
            resources: [.process("Resources")]
        ),
        .target(
            name: "LoginItemsFeature",
            dependencies: ["CleanMacCore", "CleanMacUI"],
            resources: [.process("Resources")]
        ),
        .target(
            name: "MonitorFeature",
            dependencies: ["CleanMacCore", "CleanMacUI"],
            resources: [.process("Resources")]
        ),
        .target(
            name: "OnboardingFeature",
            dependencies: ["CleanMacCore", "CleanMacUI"],
            resources: [.process("Resources")]
        ),
        .executableTarget(
            name: "CleanMacApp",
            dependencies: [
                "CleanMacCore", "CleanMacUI", "SystemJunkFeature", "UninstallerFeature",
                "LargeFilesFeature", "DiskMapFeature", "DuplicatesFeature", "MaintenanceFeature",
                "LoginItemsFeature", "PrivacyFeature", "MonitorFeature", "OnboardingFeature",
                "Sparkle"
            ],
            resources: [.process("Resources")],
            linkerSettings: [
                .unsafeFlags([
                    "-Xlinker", "-rpath",
                    "-Xlinker", "@executable_path/../Frameworks",
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
        ),
        .testTarget(
            name: "LargeFilesFeatureTests",
            dependencies: ["LargeFilesFeature", "CleanMacCore"]
        ),
        .testTarget(
            name: "MaintenanceFeatureTests",
            dependencies: ["MaintenanceFeature", "CleanMacCore"]
        ),
        .testTarget(
            name: "UninstallerFeatureTests",
            dependencies: ["UninstallerFeature", "CleanMacCore"]
        ),
        .testTarget(
            name: "DuplicatesFeatureTests",
            dependencies: ["DuplicatesFeature", "CleanMacCore"]
        ),
        .testTarget(
            name: "DiskMapFeatureTests",
            dependencies: ["DiskMapFeature", "CleanMacCore"]
        ),
        .testTarget(
            name: "PrivacyFeatureTests",
            dependencies: ["PrivacyFeature", "CleanMacCore"]
        ),
        .testTarget(
            name: "LoginItemsFeatureTests",
            dependencies: ["LoginItemsFeature", "CleanMacCore"]
        ),
        .testTarget(
            name: "MonitorFeatureTests",
            dependencies: ["MonitorFeature", "CleanMacCore"]
        ),
        .testTarget(
            name: "OnboardingFeatureTests",
            dependencies: ["OnboardingFeature", "CleanMacCore"]
        ),
        .testTarget(name: "CleanMacAppTests", dependencies: ["CleanMacApp", "CleanMacUI"]),
        .testTarget(name: "CleanMacUITests", dependencies: ["CleanMacUI"]),
        .testTarget(name: "LocalizationTests")
    ]
)
